import os
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from google.oauth2 import id_token
from google.auth.transport import requests

from app.database import get_db
from app.models.user import User
from app.schemas.auth import AuthResponse
from app.utils.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Google Auth"])

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")


class GoogleAuthRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=AuthResponse)
async def google_auth(req: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    if not GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Google Client ID not configured")
    try:
        info = id_token.verify_oauth2_token(
            req.id_token, requests.Request(), GOOGLE_CLIENT_ID
        )
    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

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