import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.user import User
from app.models.server import ServerMember
from app.models.message import Message
from app.models.channel import Channel
from app.schemas.message import MessageCreate, MessageUpdate, MessageResponse
from app.security import get_current_active_user

router = APIRouter(prefix="/channels/{channel_id}/messages", tags=["messages"])


async def verify_channel_access(channel_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession):
    channel_result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = channel_result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status_code=404, detail="Channel not found")

    member_result = await db.execute(
        select(ServerMember).where(
            ServerMember.server_id == channel.server_id,
            ServerMember.user_id == user_id,
        )
    )
    if not member_result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Not a member of this server")
    return channel


@router.post("", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    channel_id: uuid.UUID,
    message_in: MessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_channel_access(channel_id, current_user.id, db)

    if message_in.reply_to_id:
        reply = await db.execute(
            select(Message).where(
                Message.id == message_in.reply_to_id,
                Message.channel_id == channel_id,
            )
        )
        if not reply.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Reply message not found in this channel")

    message = Message(
        content=message_in.content,
        encrypted=message_in.encrypted,
        channel_id=channel_id,
        author_id=current_user.id,
        reply_to_id=message_in.reply_to_id,
    )
    db.add(message)
    await db.flush()
    await db.refresh(message)

    return MessageResponse(
        id=message.id,
        content=message.content,
        encrypted=message.encrypted,
        channel_id=message.channel_id,
        author_id=message.author_id,
        author_username=current_user.username,
        author_avatar=current_user.avatar_url,
        reply_to_id=message.reply_to_id,
        edited_at=message.edited_at,
        created_at=message.created_at,
    )


@router.get("", response_model=List[MessageResponse])
async def list_messages(
    channel_id: uuid.UUID,
    before: Optional[uuid.UUID] = None,
    limit: int = Query(default=50, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_channel_access(channel_id, current_user.id, db)

    query = (
        select(Message, User)
        .join(User, Message.author_id == User.id)
        .where(Message.channel_id == channel_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    if before:
        before_msg = await db.execute(select(Message).where(Message.id == before))
        before_msg = before_msg.scalar_one_or_none()
        if before_msg:
            query = query.where(Message.created_at < before_msg.created_at)

    result = await db.execute(query)
    rows = result.all()

    return [
        MessageResponse(
            id=m.id,
            content=m.content,
            encrypted=m.encrypted,
            channel_id=m.channel_id,
            author_id=m.author_id,
            author_username=u.username,
            author_avatar=u.avatar_url,
            reply_to_id=m.reply_to_id,
            edited_at=m.edited_at,
            created_at=m.created_at,
        )
        for m, u in rows
    ]


@router.put("/{message_id}", response_model=MessageResponse)
async def update_message(
    channel_id: uuid.UUID,
    message_id: uuid.UUID,
    message_in: MessageUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_channel_access(channel_id, current_user.id, db)

    result = await db.execute(
        select(Message).where(Message.id == message_id, Message.channel_id == channel_id)
    )
    message = result.scalar_one_or_none()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    if message.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Can only edit your own messages")

    from datetime import datetime, timezone
    message.content = message_in.content
    message.edited_at = datetime.now(timezone.utc)
    await db.flush()
    await db.refresh(message)

    return MessageResponse(
        id=message.id,
        content=message.content,
        encrypted=message.encrypted,
        channel_id=message.channel_id,
        author_id=message.author_id,
        author_username=current_user.username,
        author_avatar=current_user.avatar_url,
        reply_to_id=message.reply_to_id,
        edited_at=message.edited_at,
        created_at=message.created_at,
    )


@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    channel_id: uuid.UUID,
    message_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_channel_access(channel_id, current_user.id, db)

    result = await db.execute(
        select(Message).where(Message.id == message_id, Message.channel_id == channel_id)
    )
    message = result.scalar_one_or_none()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    if message.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Can only delete your own messages")
    await db.delete(message)
