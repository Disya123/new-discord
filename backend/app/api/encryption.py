import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.dm import OneTimePreKey
from app.schemas.encryption import PreKeyUpload, PreKeyBundle
from app.security import get_current_active_user

router = APIRouter(prefix="/encryption", tags=["encryption"])


@router.post("/keys", status_code=201)
async def upload_prekeys(
    keys_in: PreKeyUpload,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    current_user.identity_key_public = keys_in.identity_key_public
    current_user.signed_prekey_public = keys_in.signed_prekey_public
    current_user.signed_prekey_signature = keys_in.signed_prekey_signature

    existing_keys = await db.execute(
        select(OneTimePreKey).where(OneTimePreKey.user_id == current_user.id, OneTimePreKey.used == False)
    )
    for key in existing_keys.scalars().all():
        await db.delete(key)

    for key_data in keys_in.onetime_prekeys:
        prekey = OneTimePreKey(
            user_id=current_user.id,
            key_id=key_data["key_id"],
            public_key=key_data["public_key"],
        )
        db.add(prekey)

    await db.flush()
    return {"status": "keys_uploaded", "prekeys_count": len(keys_in.onetime_prekeys)}


@router.get("/prekey-bundle/{user_id}", response_model=PreKeyBundle)
async def get_prekey_bundle(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.identity_key_public:
        raise HTTPException(status_code=404, detail="User has not uploaded encryption keys")

    prekey_result = await db.execute(
        select(OneTimePreKey).where(
            OneTimePreKey.user_id == user_id,
            OneTimePreKey.used == False,
        ).order_by(OneTimePreKey.created_at).limit(1)
    )
    prekey = prekey_result.scalar_one_or_none()
    if not prekey:
        raise HTTPException(status_code=404, detail="No prekeys available")

    prekey.used = True
    await db.flush()

    return PreKeyBundle(
        user_id=user.id,
        identity_key_public=user.identity_key_public,
        signed_prekey_public=user.signed_prekey_public,
        signed_prekey_signature=user.signed_prekey_signature,
        prekey_id=prekey.key_id,
        prekey_public=prekey.public_key,
    )


@router.get("/identity-key/{user_id}")
async def get_identity_key(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.identity_key_public:
        raise HTTPException(status_code=404, detail="User or key not found")
    return {"user_id": user.id, "identity_key_public": user.identity_key_public}
