from pydantic import BaseModel
from typing import Optional, List
import uuid


class IdentityKeyBundle(BaseModel):
    identity_key_public: str
    signed_prekey_public: str
    signed_prekey_signature: str


class PreKeyBundle(BaseModel):
    user_id: uuid.UUID
    identity_key_public: str
    signed_prekey_public: str
    signed_prekey_signature: str
    prekey_id: int
    prekey_public: str


class PreKeyUpload(BaseModel):
    identity_key_public: str
    signed_prekey_public: str
    signed_prekey_signature: str
    onetime_prekeys: List[dict]


class SessionEstablished(BaseModel):
    session_id: str
    peer_user_id: uuid.UUID
    established: bool
