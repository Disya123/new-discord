from pydantic import BaseModel, Field
from typing import Optional
import uuid
from datetime import datetime


class ChannelCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    type: str = Field(default="text", pattern=r"^(text|voice)$")
    topic: Optional[str] = None


class ChannelUpdate(BaseModel):
    name: Optional[str] = None
    topic: Optional[str] = None
    position: Optional[int] = None


class ChannelResponse(BaseModel):
    id: uuid.UUID
    name: str
    type: str
    server_id: uuid.UUID
    position: int
    topic: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
