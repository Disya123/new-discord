import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.user import User
from app.models.server import Server, ServerMember
from app.models.channel import Channel
from app.schemas.server import ServerCreate, ServerUpdate, ServerResponse, ServerMemberResponse, InviteResponse
from app.security import get_current_active_user
import secrets
import string

router = APIRouter(prefix="/servers", tags=["servers"])


def generate_invite_code(length: int = 8) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


@router.post("", response_model=ServerResponse, status_code=status.HTTP_201_CREATED)
async def create_server(
    server_in: ServerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    server = Server(
        name=server_in.name,
        description=server_in.description,
        owner_id=current_user.id,
        invite_code=generate_invite_code(),
    )
    db.add(server)
    await db.flush()

    member = ServerMember(server_id=server.id, user_id=current_user.id, role="owner")
    db.add(member)

    default_channels = [
        Channel(name="general", type="text", server_id=server.id, position=0),
        Channel(name="voice", type="voice", server_id=server.id, position=1),
    ]
    db.add_all(default_channels)
    await db.flush()
    await db.refresh(server)
    return server


@router.get("", response_model=List[ServerResponse])
async def list_user_servers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(Server)
        .join(ServerMember)
        .where(ServerMember.user_id == current_user.id)
        .order_by(Server.created_at)
    )
    return result.scalars().all()


@router.get("/{server_id}", response_model=ServerResponse)
async def get_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(Server).where(Server.id == server_id))
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")

    member = await db.execute(
        select(ServerMember).where(
            ServerMember.server_id == server_id,
            ServerMember.user_id == current_user.id,
        )
    )
    if not member.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Not a member of this server")
    return server


@router.put("/{server_id}", response_model=ServerResponse)
async def update_server(
    server_id: uuid.UUID,
    server_in: ServerUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(Server).where(Server.id == server_id))
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    if server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can update the server")

    for field, value in server_in.model_dump(exclude_unset=True).items():
        setattr(server, field, value)
    await db.flush()
    await db.refresh(server)
    return server


@router.delete("/{server_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(Server).where(Server.id == server_id))
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    if server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete the server")
    await db.delete(server)


@router.post("/{server_id}/join", response_model=ServerMemberResponse)
async def join_server(
    server_id: uuid.UUID,
    invite_code: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(Server).where(Server.id == server_id))
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    if server.invite_code != invite_code:
        raise HTTPException(status_code=400, detail="Invalid invite code")

    existing = await db.execute(
        select(ServerMember).where(
            ServerMember.server_id == server_id,
            ServerMember.user_id == current_user.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Already a member")

    member = ServerMember(server_id=server_id, user_id=current_user.id, role="member")
    db.add(member)
    await db.flush()
    await db.refresh(member)

    return ServerMemberResponse(
        id=member.id,
        user_id=current_user.id,
        username=current_user.username,
        display_name=current_user.display_name,
        avatar_url=current_user.avatar_url,
        nickname=member.nickname,
        role=member.role,
        is_online=current_user.is_online,
        status=current_user.status,
        joined_at=member.joined_at,
    )


@router.get("/{server_id}/members", response_model=List[ServerMemberResponse])
async def list_members(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    member_check = await db.execute(
        select(ServerMember).where(
            ServerMember.server_id == server_id,
            ServerMember.user_id == current_user.id,
        )
    )
    if not member_check.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Not a member")

    result = await db.execute(
        select(ServerMember, User)
        .join(User, ServerMember.user_id == User.id)
        .where(ServerMember.server_id == server_id)
    )
    rows = result.all()
    return [
        ServerMemberResponse(
            id=sm.id,
            user_id=u.id,
            username=u.username,
            display_name=u.display_name,
            avatar_url=u.avatar_url,
            nickname=sm.nickname,
            role=sm.role,
            is_online=u.is_online,
            status=u.status,
            joined_at=sm.joined_at,
        )
        for sm, u in rows
    ]


@router.post("/{server_id}/invite", response_model=InviteResponse)
async def regenerate_invite(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(Server).where(Server.id == server_id))
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    if server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can regenerate invite")

    server.invite_code = generate_invite_code()
    await db.flush()
    return InviteResponse(invite_code=server.invite_code, server_id=server.id)
