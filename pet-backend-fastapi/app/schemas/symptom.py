import uuid

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime


class SymptomAnalyzeRequest(BaseModel):
    pet_id: str
    text: str = Field(..., min_length=1, max_length=5000)
    pet_species: Optional[str] = None
    pet_age: Optional[int] = None
    pet_breed: Optional[str] = None
    pet_weight_kg: Optional[float] = None


class SymptomAnalyzeResponse(BaseModel):
    risk_level: str
    possible_conditions: List[str]
    confidence: float
    recommendation: str
    is_emergency: bool
    emergency_actions: Optional[List[str]] = None


class SymptomRecordOut(BaseModel):
    id: str
    pet_id: str
    symptoms_text: str
    risk_level: Optional[str] = None
    is_emergency: bool
    ai_diagnosis: Optional[dict] = None
    created_at: datetime

    @field_validator("id", "pet_id", mode="before")
    @classmethod
    def coerce_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v

    class Config:
        from_attributes = True
