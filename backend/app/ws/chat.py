import uuid
import json
from datetime import datetime, timezone
from typing import Optional

from fastapi import WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session
from app.models.user import User
from app.models.message import Message
from app.models.dm import DMMessage, DMConversation
from app.models.channel import Channel
from app.models.server import ServerMember
from app.ws.manager import manager
from app.security.jwt import decode_token


async def get_user_from_token(token: str) -> Optional[User]:
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        return None
    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, KeyError):
        return None
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()


async def websocket_endpoint(websocket: WebSocket, token: str = Query(...)):
    user = await get_user_from_token(token)
    if not user:
        await websocket.close(code=4001)
        return

    await manager.connect(user.id, websocket)

    user.is_online = True
    user.status = "online"
    async with async_session() as db:
        db_user = await db.execute(select(User).where(User.id == user.id))
        db_user = db_user.scalar_one_or_none()
        if db_user:
            db_user.is_online = True
            db_user.status = "online"
            await db.commit()

    await manager.broadcast_to_all({
        "type": "presence_update",
        "user_id": str(user.id),
        "is_online": True,
        "status": "online",
    })

    try:
        while True:
            data = await websocket.receive_json()
            await handle_message(user.id, data)
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(user.id)
        async with async_session() as db:
            db_user = await db.execute(select(User).where(User.id == user.id))
            db_user = db_user.scalar_one_or_none()
            if db_user:
                db_user.is_online = False
                db_user.status = "offline"
                await db.commit()

        await manager.broadcast_to_all({
            "type": "presence_update",
            "user_id": str(user.id),
            "is_online": False,
            "status": "offline",
        })


async def handle_message(user_id: uuid.UUID, data: dict):
    msg_type = data.get("type")

    if msg_type == "subscribe_channel":
        channel_id = uuid.UUID(data["channel_id"])
        manager.subscribe_channel(user_id, channel_id)

    elif msg_type == "unsubscribe_channel":
        channel_id = uuid.UUID(data["channel_id"])
        manager.unsubscribe_channel(user_id, channel_id)

    elif msg_type == "chat_message":
        await handle_chat_message(user_id, data)

    elif msg_type == "dm_message":
        await handle_dm_message(user_id, data)

    elif msg_type == "typing_start":
        channel_id = uuid.UUID(data["channel_id"])
        await manager.broadcast_to_channel(channel_id, {
            "type": "typing_start",
            "user_id": str(user_id),
            "channel_id": str(channel_id),
        }, exclude=user_id)

    elif msg_type == "typing_stop":
        channel_id = uuid.UUID(data["channel_id"])
        await manager.broadcast_to_channel(channel_id, {
            "type": "typing_stop",
            "user_id": str(user_id),
            "channel_id": str(channel_id),
        }, exclude=user_id)

    elif msg_type == "join_voice":
        channel_id = uuid.UUID(data["channel_id"])
        manager.join_voice_channel(user_id, channel_id)
        await manager.broadcast_to_all({
            "type": "voice_user_joined",
            "user_id": str(user_id),
            "channel_id": str(channel_id),
        })

    elif msg_type == "leave_voice":
        channel_id = uuid.UUID(data["channel_id"])
        manager.leave_voice_channel(user_id, channel_id)
        await manager.broadcast_to_all({
            "type": "voice_user_left",
            "user_id": str(user_id),
            "channel_id": str(channel_id),
        })

    elif msg_type == "webrtc_signal":
        target_id = uuid.UUID(data["target_user_id"])
        await manager.send_to_user(target_id, {
            "type": "webrtc_signal",
            "from_user_id": str(user_id),
            "signal": data["signal"],
        })


async def handle_chat_message(user_id: uuid.UUID, data: dict):
    channel_id = uuid.UUID(data["channel_id"])
    content = data["content"]
    encrypted = data.get("encrypted", False)
    reply_to_id = data.get("reply_to_id")

    async with async_session() as db:
        user_result = await db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        if not user:
            return

        message = Message(
            content=content,
            encrypted=encrypted,
            channel_id=channel_id,
            author_id=user_id,
            reply_to_id=uuid.UUID(reply_to_id) if reply_to_id else None,
        )
        db.add(message)
        await db.commit()
        await db.refresh(message)

    await manager.broadcast_to_channel(channel_id, {
        "type": "new_message",
        "message": {
            "id": str(message.id),
            "content": message.content,
            "encrypted": message.encrypted,
            "channel_id": str(message.channel_id),
            "author_id": str(message.author_id),
            "author_username": user.username,
            "author_avatar": user.avatar_url,
            "reply_to_id": str(message.reply_to_id) if message.reply_to_id else None,
            "created_at": message.created_at.isoformat(),
        },
    })


async def handle_dm_message(user_id: uuid.UUID, data: dict):
    conversation_id = uuid.UUID(data["conversation_id"])
    content = data["content"]
    encrypted = data.get("encrypted", False)

    async with async_session() as db:
        user_result = await db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        conv_result = await db.execute(select(DMConversation).where(DMConversation.id == conversation_id))
        conv = conv_result.scalar_one_or_none()
        if not user or not conv:
            return

        message = DMMessage(
            content=content,
            encrypted=encrypted,
            conversation_id=conversation_id,
            author_id=user_id,
        )
        db.add(message)
        await db.commit()
        await db.refresh(message)

    recipient_id = conv.user2_id if conv.user1_id == user_id else conv.user1_id

    dm_payload = {
        "type": "new_dm_message",
        "message": {
            "id": str(message.id),
            "content": message.content,
            "encrypted": message.encrypted,
            "conversation_id": str(message.conversation_id),
            "author_id": str(message.author_id),
            "author_username": user.username,
            "author_avatar": user.avatar_url,
            "read": message.read,
            "created_at": message.created_at.isoformat(),
        },
    }
    await manager.send_to_user(recipient_id, dm_payload)
    await manager.send_to_user(user_id, dm_payload)
