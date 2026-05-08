import uuid
from typing import Dict, Set, Optional
from fastapi import WebSocket
import json


class ConnectionManager:
    def __init__(self):
        self._connections: Dict[uuid.UUID, WebSocket] = {}
        self._user_channels: Dict[uuid.UUID, Set[uuid.UUID]] = {}
        self._channel_subscribers: Dict[uuid.UUID, Set[uuid.UUID]] = {}
        self._voice_channels: Dict[uuid.UUID, Set[uuid.UUID]] = {}

    async def connect(self, user_id: uuid.UUID, websocket: WebSocket):
        await websocket.accept()
        self._connections[user_id] = websocket
        self._user_channels[user_id] = set()

    def disconnect(self, user_id: uuid.UUID):
        self._connections.pop(user_id, None)
        channels = self._user_channels.pop(user_id, set())
        for ch_id in channels:
            self._channel_subscribers.get(ch_id, set()).discard(user_id)
        for vc_users in self._voice_channels.values():
            vc_users.discard(user_id)

    def subscribe_channel(self, user_id: uuid.UUID, channel_id: uuid.UUID):
        if channel_id not in self._channel_subscribers:
            self._channel_subscribers[channel_id] = set()
        self._channel_subscribers[channel_id].add(user_id)
        if user_id in self._user_channels:
            self._user_channels[user_id].add(channel_id)

    def unsubscribe_channel(self, user_id: uuid.UUID, channel_id: uuid.UUID):
        self._channel_subscribers.get(channel_id, set()).discard(user_id)
        if user_id in self._user_channels:
            self._user_channels[user_id].discard(channel_id)

    async def send_to_user(self, user_id: uuid.UUID, message: dict):
        ws = self._connections.get(user_id)
        if ws:
            try:
                await ws.send_json(message)
            except Exception:
                self.disconnect(user_id)

    async def broadcast_to_channel(self, channel_id: uuid.UUID, message: dict, exclude: Optional[uuid.UUID] = None):
        subscribers = self._channel_subscribers.get(channel_id, set())
        for user_id in subscribers:
            if user_id != exclude:
                await self.send_to_user(user_id, message)

    async def broadcast_to_all(self, message: dict, exclude: Optional[uuid.UUID] = None):
        for user_id in list(self._connections.keys()):
            if user_id != exclude:
                await self.send_to_user(user_id, message)

    def join_voice_channel(self, user_id: uuid.UUID, channel_id: uuid.UUID):
        if channel_id not in self._voice_channels:
            self._voice_channels[channel_id] = set()
        self._voice_channels[channel_id].add(user_id)

    def leave_voice_channel(self, user_id: uuid.UUID, channel_id: uuid.UUID):
        self._voice_channels.get(channel_id, set()).discard(user_id)

    def get_voice_users(self, channel_id: uuid.UUID) -> Set[uuid.UUID]:
        return self._voice_channels.get(channel_id, set()).copy()

    def get_online_users(self) -> Set[uuid.UUID]:
        return set(self._connections.keys())

    def is_online(self, user_id: uuid.UUID) -> bool:
        return user_id in self._connections


manager = ConnectionManager()
