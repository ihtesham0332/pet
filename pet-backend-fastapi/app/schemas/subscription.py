from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class SubscriptionStatus(BaseModel):
    tier: str
    status: str
    started_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    features: dict = Field(default_factory=lambda: {
        "max_pets": 1,
        "symptom_checks_per_month": 3,
        "ai_analysis": True,
        "emergency_alerts": True,
        "telehealth": False,
        "weight_tracking": True,
        "reminder_system": True,
    })


class UpgradeRequest(BaseModel):
    tier: str = Field(..., pattern="^(premium|pro)$")


class SubscriptionAction(BaseModel):
    detail: str
    success: bool
