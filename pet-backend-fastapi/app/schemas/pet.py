import uuid

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime, date


class PetCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    species: str = Field(..., pattern="^(dog|cat|other)$")
    breed: Optional[str] = None
    date_of_birth: Optional[date] = None
    weight_kg: Optional[float] = Field(None, ge=0, le=200)


class PetUpdate(BaseModel):
    name: Optional[str] = None
    breed: Optional[str] = None
    date_of_birth: Optional[date] = None
    weight_kg: Optional[float] = Field(None, ge=0, le=200)
    medical_history: Optional[str] = None
    avatar_url: Optional[str] = None


class PetOut(BaseModel):
    id: str
    user_id: str
    name: str
    species: str
    breed: Optional[str] = None
    date_of_birth: Optional[date] = None
    weight_kg: Optional[float] = None
    medical_history: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: datetime

    @field_validator("id", "user_id", mode="before")
    @classmethod
    def coerce_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v

    class Config:
        from_attributes = True
