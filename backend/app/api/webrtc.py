import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.security import get_current_active_user
from app.config import settings

router = APIRouter(prefix="/webrtc", tags=["webrtc"])


@router.get("/ice-servers")
async def get_ice_servers(current_user: User = Depends(get_current_active_user)):
    return {
        "iceServers": [
            {"urls": "stun:stun.l.google.com:19302"},
            {
                "urls": settings.TURN_URL,
                "username": settings.TURN_USERNAME,
                "credential": settings.TURN_PASSWORD,
            },
        ]
    }
