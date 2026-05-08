from fastapi import APIRouter

from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.servers import router as servers_router
from app.api.channels import router as channels_router
from app.api.messages import router as messages_router
from app.api.dm import router as dm_router
from app.api.encryption import router as encryption_router
from app.api.webrtc import router as webrtc_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(servers_router)
api_router.include_router(channels_router)
api_router.include_router(messages_router)
api_router.include_router(dm_router)
api_router.include_router(encryption_router)
api_router.include_router(webrtc_router)
