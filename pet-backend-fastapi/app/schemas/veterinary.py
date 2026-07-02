import uuid

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime


class AppointmentCreate(BaseModel):
    pet_id: str
    vet_name: str = Field(..., min_length=1, max_length=255)
    vet_clinic: Optional[str] = None
    scheduled_at: datetime
    type: Optional[str] = "telehealth"


class AppointmentOut(BaseModel):
    id: str
    pet_id: str
    vet_name: str
    vet_clinic: Optional[str] = None
    scheduled_at: datetime
    status: str
    type: str
    notes: Optional[str] = None
    created_at: datetime

    @field_validator("id", "pet_id", mode="before")
    @classmethod
    def coerce_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v

    class Config:
        from_attributes = True
