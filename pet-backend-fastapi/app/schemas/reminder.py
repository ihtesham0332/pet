import uuid

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime


class ReminderCreate(BaseModel):
    pet_id: Optional[str] = None
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    reminder_type: str = Field(default="checkup", pattern="^(vaccination|checkup|medication|grooming|custom)$")
    scheduled_date: datetime


class ReminderUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    reminder_type: Optional[str] = Field(None, pattern="^(vaccination|checkup|medication|grooming|custom)$")
    scheduled_date: Optional[datetime] = None
    status: Optional[str] = Field(None, pattern="^(pending|completed|cancelled)$")


class ReminderOut(BaseModel):
    id: str
    user_id: str
    pet_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    reminder_type: str
    scheduled_date: datetime
    status: str
    created_at: datetime
    updated_at: datetime

    @field_validator("id", "user_id", "pet_id", mode="before")
    @classmethod
    def coerce_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v

    class Config:
        from_attributes = True


class ReminderList(BaseModel):
    reminders: List[ReminderOut]
    total: int
