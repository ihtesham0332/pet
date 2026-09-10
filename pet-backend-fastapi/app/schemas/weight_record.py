import uuid

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime


class WeightRecordCreate(BaseModel):
    weight_kg: float = Field(..., gt=0, le=200)
    measured_at: Optional[datetime] = None
    notes: Optional[str] = None


class WeightRecordOut(BaseModel):
    id: str
    pet_id: str
    weight_kg: float
    measured_at: datetime
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


class WeightRecordList(BaseModel):
    records: List[WeightRecordOut]
    total: int
