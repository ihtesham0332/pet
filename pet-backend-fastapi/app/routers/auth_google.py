import json
import base64
import os
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.schemas.auth import AuthResponse
from app.utils.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Google Auth"])


def _decode_google_token(token: str) -> dict:
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Invalid JWT token")
    payload = parts[1]
    padding = 4 - len(payload) % 4
    if padding != 4:
        payload += "=" * padding
    return json.loads(base64.urlsafe_b64decode(payload))


class GoogleAuthRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=AuthResponse)
async def google_auth(req: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    try:
        info = _decode_google_token(req.id_token)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid token: {e}")

    email = info.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email not provided by Google")

    name = info.get("name", email.split("@")[0])
    picture = info.get("picture", "")

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=email,
            name=name,
            password_hash="",
            photo_url=picture,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    token = create_access_token(data={"sub": str(user.id)})

    return AuthResponse(
        access_token=token,
        token_type="bearer",
        user={
            "id": str(user.id),
            "email": user.email,
            "name": user.name,
            "photo_url": user.photo_url or picture,
            "subscription_tier": user.subscription_tier or "free",
            "created_at": user.created_at.isoformat() if user.created_at else datetime.utcnow().isoformat(),
        },
    )