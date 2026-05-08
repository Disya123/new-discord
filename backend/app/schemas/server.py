from pydantic import BaseModel, Field
from typing import Optional, List
import uuid
from datetime import datetime


class ServerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None


class ServerUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon_url: Optional[str] = None


class ServerResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    invite_code: Optional[str] = None
    owner_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True


class ServerMemberResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    username: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    nickname: Optional[str] = None
    role: str
    is_online: bool
    status: str
    joined_at: datetime

    class Config:
        from_attributes = True


class InviteResponse(BaseModel):
    invite_code: str
    server_id: uuid.UUID
