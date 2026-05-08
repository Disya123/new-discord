from pydantic import BaseModel, Field
from typing import Optional, List
import uuid
from datetime import datetime


class MessageCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)
    encrypted: bool = False
    reply_to_id: Optional[uuid.UUID] = None


class MessageUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)


class MessageResponse(BaseModel):
    id: uuid.UUID
    content: str
    encrypted: bool
    channel_id: uuid.UUID
    author_id: uuid.UUID
    author_username: str
    author_avatar: Optional[str] = None
    reply_to_id: Optional[uuid.UUID] = None
    edited_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DMMessageCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)
    encrypted: bool = False


class DMMessageResponse(BaseModel):
    id: uuid.UUID
    content: str
    encrypted: bool
    conversation_id: uuid.UUID
    author_id: uuid.UUID
    author_username: str
    author_avatar: Optional[str] = None
    read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class DMConversationResponse(BaseModel):
    id: uuid.UUID
    user1_id: uuid.UUID
    user2_id: uuid.UUID
    other_user_id: uuid.UUID
    other_username: str
    other_avatar: Optional[str] = None
    other_is_online: bool
    last_message: Optional[DMMessageResponse] = None
    unread_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True
