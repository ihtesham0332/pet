import uuid

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: str
    email: str
    name: str
    role: str
    subscription_tier: str
    photo_url: Optional[str] = None
    created_at: datetime

    @field_validator("id", mode="before")
    @classmethod
    def coerce_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    token: str
    user: UserOut


class UserUpdate(BaseModel):
    name: Optional[str] = None
    photo_url: Optional[str] = None


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict