import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, or_, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.dm import DMConversation, DMMessage
from app.schemas.message import DMMessageCreate, DMMessageResponse, DMConversationResponse
from app.security import get_current_active_user

router = APIRouter(prefix="/dm", tags=["direct-messages"])


@router.get("/conversations", response_model=List[DMConversationResponse])
async def list_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(DMConversation).where(
            or_(
                DMConversation.user1_id == current_user.id,
                DMConversation.user2_id == current_user.id,
            )
        )
    )
    conversations = result.scalars().all()

    response = []
    for conv in conversations:
        other_id = conv.user2_id if conv.user1_id == current_user.id else conv.user1_id
        other_user = await db.execute(select(User).where(User.id == other_id))
        other = other_user.scalar_one_or_none()

        last_msg_result = await db.execute(
            select(DMMessage)
            .where(DMMessage.conversation_id == conv.id)
            .order_by(DMMessage.created_at.desc())
            .limit(1)
        )
        last_msg = last_msg_result.scalar_one_or_none()

        unread_result = await db.execute(
            select(func.count()).where(
                DMMessage.conversation_id == conv.id,
                DMMessage.author_id != current_user.id,
                DMMessage.read == False,
            )
        )
        unread_count = unread_result.scalar() or 0

        last_message = None
        if last_msg:
            author = await db.execute(select(User).where(User.id == last_msg.author_id))
            author_user = author.scalar_one_or_none()
            last_message = DMMessageResponse(
                id=last_msg.id,
                content=last_msg.content,
                encrypted=last_msg.encrypted,
                conversation_id=last_msg.conversation_id,
                author_id=last_msg.author_id,
                author_username=author_user.username if author_user else "unknown",
                author_avatar=author_user.avatar_url if author_user else None,
                read=last_msg.read,
                created_at=last_msg.created_at,
            )

        response.append(DMConversationResponse(
            id=conv.id,
            user1_id=conv.user1_id,
            user2_id=conv.user2_id,
            other_user_id=other_id,
            other_username=other.username if other else "unknown",
            other_avatar=other.avatar_url if other else None,
            other_is_online=other.is_online if other else False,
            last_message=last_message,
            unread_count=unread_count,
            created_at=conv.created_at,
        ))

    return response


@router.post("/conversations/{user_id}", response_model=DMConversationResponse)
async def get_or_create_conversation(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot create conversation with yourself")

    other = await db.execute(select(User).where(User.id == user_id))
    other_user = other.scalar_one_or_none()
    if not other_user:
        raise HTTPException(status_code=404, detail="User not found")

    result = await db.execute(
        select(DMConversation).where(
            or_(
                and_(DMConversation.user1_id == current_user.id, DMConversation.user2_id == user_id),
                and_(DMConversation.user1_id == user_id, DMConversation.user2_id == current_user.id),
            )
        )
    )
    conv = result.scalar_one_or_none()

    if not conv:
        conv = DMConversation(user1_id=current_user.id, user2_id=user_id)
        db.add(conv)
        await db.flush()
        await db.refresh(conv)

    return DMConversationResponse(
        id=conv.id,
        user1_id=conv.user1_id,
        user2_id=conv.user2_id,
        other_user_id=user_id,
        other_username=other_user.username,
        other_avatar=other_user.avatar_url,
        other_is_online=other_user.is_online,
        last_message=None,
        unread_count=0,
        created_at=conv.created_at,
    )


@router.get("/conversations/{conversation_id}/messages", response_model=List[DMMessageResponse])
async def list_dm_messages(
    conversation_id: uuid.UUID,
    before: Optional[uuid.UUID] = None,
    limit: int = Query(default=50, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    conv_result = await db.execute(
        select(DMConversation).where(
            DMConversation.id == conversation_id,
            or_(
                DMConversation.user1_id == current_user.id,
                DMConversation.user2_id == current_user.id,
            ),
        )
    )
    conv = conv_result.scalar_one_or_none()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    query = (
        select(DMMessage, User)
        .join(User, DMMessage.author_id == User.id)
        .where(DMMessage.conversation_id == conversation_id)
        .order_by(DMMessage.created_at.desc())
        .limit(limit)
    )
    if before:
        before_msg = await db.execute(select(DMMessage).where(DMMessage.id == before))
        before_msg = before_msg.scalar_one_or_none()
        if before_msg:
            query = query.where(DMMessage.created_at < before_msg.created_at)

    result = await db.execute(query)
    rows = result.all()

    return [
        DMMessageResponse(
            id=m.id,
            content=m.content,
            encrypted=m.encrypted,
            conversation_id=m.conversation_id,
            author_id=m.author_id,
            author_username=u.username,
            author_avatar=u.avatar_url,
            read=m.read,
            created_at=m.created_at,
        )
        for m, u in rows
    ]


@router.post("/conversations/{conversation_id}/messages", response_model=DMMessageResponse)
async def send_dm_message(
    conversation_id: uuid.UUID,
    message_in: DMMessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    conv_result = await db.execute(
        select(DMConversation).where(
            DMConversation.id == conversation_id,
            or_(
                DMConversation.user1_id == current_user.id,
                DMConversation.user2_id == current_user.id,
            ),
        )
    )
    conv = conv_result.scalar_one_or_none()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    message = DMMessage(
        content=message_in.content,
        encrypted=message_in.encrypted,
        conversation_id=conversation_id,
        author_id=current_user.id,
    )
    db.add(message)
    await db.flush()
    await db.refresh(message)

    return DMMessageResponse(
        id=message.id,
        content=message.content,
        encrypted=message.encrypted,
        conversation_id=message.conversation_id,
        author_id=message.author_id,
        author_username=current_user.username,
        author_avatar=current_user.avatar_url,
        read=message.read,
        created_at=message.created_at,
    )


@router.put("/conversations/{conversation_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_as_read(
    conversation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    conv_result = await db.execute(
        select(DMConversation).where(
            DMConversation.id == conversation_id,
            or_(
                DMConversation.user1_id == current_user.id,
                DMConversation.user2_id == current_user.id,
            ),
        )
    )
    conv = conv_result.scalar_one_or_none()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    await db.execute(
        DMMessage.__table__.update()
        .where(
            DMMessage.conversation_id == conversation_id,
            DMMessage.author_id != current_user.id,
            DMMessage.read == False,
        )
        .values(read=True)
    )
