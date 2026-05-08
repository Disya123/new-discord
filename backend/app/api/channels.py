import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.server import Server, ServerMember
from app.models.channel import Channel
from app.schemas.channel import ChannelCreate, ChannelUpdate, ChannelResponse
from app.security import get_current_active_user

router = APIRouter(prefix="/servers/{server_id}/channels", tags=["channels"])


async def verify_membership(server_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession):
    result = await db.execute(
        select(ServerMember).where(
            ServerMember.server_id == server_id,
            ServerMember.user_id == user_id,
        )
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Not a member of this server")


@router.post("", response_model=ChannelResponse, status_code=status.HTTP_201_CREATED)
async def create_channel(
    server_id: uuid.UUID,
    channel_in: ChannelCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    server_result = await db.execute(select(Server).where(Server.id == server_id))
    server = server_result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    if server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can create channels")

    pos_result = await db.execute(
        select(Channel).where(Channel.server_id == server_id).order_by(Channel.position.desc()).limit(1)
    )
    last_channel = pos_result.scalar_one_or_none()
    next_pos = (last_channel.position + 1) if last_channel else 0

    channel = Channel(
        name=channel_in.name,
        type=channel_in.type,
        server_id=server_id,
        position=next_pos,
        topic=channel_in.topic,
    )
    db.add(channel)
    await db.flush()
    await db.refresh(channel)
    return channel


@router.get("", response_model=List[ChannelResponse])
async def list_channels(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_membership(server_id, current_user.id, db)
    result = await db.execute(
        select(Channel).where(Channel.server_id == server_id).order_by(Channel.position)
    )
    return result.scalars().all()


@router.get("/{channel_id}", response_model=ChannelResponse)
async def get_channel(
    server_id: uuid.UUID,
    channel_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await verify_membership(server_id, current_user.id, db)
    result = await db.execute(
        select(Channel).where(Channel.id == channel_id, Channel.server_id == server_id)
    )
    channel = result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status_code=404, detail="Channel not found")
    return channel


@router.put("/{channel_id}", response_model=ChannelResponse)
async def update_channel(
    server_id: uuid.UUID,
    channel_id: uuid.UUID,
    channel_in: ChannelUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    server_result = await db.execute(select(Server).where(Server.id == server_id))
    server = server_result.scalar_one_or_none()
    if not server or server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can update channels")

    result = await db.execute(
        select(Channel).where(Channel.id == channel_id, Channel.server_id == server_id)
    )
    channel = result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status_code=404, detail="Channel not found")

    for field, value in channel_in.model_dump(exclude_unset=True).items():
        setattr(channel, field, value)
    await db.flush()
    await db.refresh(channel)
    return channel


@router.delete("/{channel_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_channel(
    server_id: uuid.UUID,
    channel_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    server_result = await db.execute(select(Server).where(Server.id == server_id))
    server = server_result.scalar_one_or_none()
    if not server or server.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete channels")

    result = await db.execute(
        select(Channel).where(Channel.id == channel_id, Channel.server_id == server_id)
    )
    channel = result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status_code=404, detail="Channel not found")
    await db.delete(channel)
