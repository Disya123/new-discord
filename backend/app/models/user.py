import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    display_name: Mapped[str] = mapped_column(String(64), nullable=True)
    avatar_url: Mapped[str] = mapped_column(String(512), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="offline")
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    identity_key_public: Mapped[str] = mapped_column(Text, nullable=True)
    signed_prekey_public: Mapped[str] = mapped_column(Text, nullable=True)
    signed_prekey_signature: Mapped[str] = mapped_column(Text, nullable=True)

    owned_servers = relationship("Server", back_populates="owner", foreign_keys="Server.owner_id")
    memberships = relationship("ServerMember", back_populates="user")
    messages = relationship("Message", back_populates="author")
    dm_messages = relationship("DMMessage", back_populates="author")
