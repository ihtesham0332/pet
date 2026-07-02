from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.user import User
from app.utils.security import hash_password, verify_password, create_access_token
from app.schemas.auth import RegisterRequest, LoginRequest


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register(self, dto: RegisterRequest) -> dict:
        existing = await self.db.execute(select(User).where(User.email == dto.email))
        if existing.scalar_one_or_none():
            raise ValueError("Email already registered")

        user = User(
            email=dto.email,
            password_hash=hash_password(dto.password),
            name=dto.name,
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        return {
            "token": create_access_token({"sub": str(user.id), "email": user.email}),
            "user": user,
        }

    async def login(self, dto: LoginRequest) -> dict:
        result = await self.db.execute(select(User).where(User.email == dto.email))
        user = result.scalar_one_or_none()

        if not user or not verify_password(dto.password, user.password_hash):
            raise ValueError("Invalid credentials")

        return {
            "token": create_access_token({"sub": str(user.id), "email": user.email}),
            "user": user,
        }
