import uuid
from typing import Optional
from datetime import datetime

from pydantic import BaseModel


class NotificationSettingsIn(BaseModel):
    push_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    appointment_reminders: Optional[bool] = None
    vaccination_reminders: Optional[bool] = None
    checkup_reminders: Optional[bool] = None
    symptom_alerts: Optional[bool] = None
    emergency_alerts: Optional[bool] = None


class NotificationSettingsOut(BaseModel):
    push_enabled: bool = True
    email_enabled: bool = True
    appointment_reminders: bool = True
    vaccination_reminders: bool = True
    checkup_reminders: bool = True
    symptom_alerts: bool = True
    emergency_alerts: bool = True


class NotificationOut(BaseModel):
    id: str
    type: str
    title: str
    body: Optional[str] = None
    payload: Optional[dict] = None
    read: bool = False
    created_at: datetime

    class Config:
        from_attributes = True

    @classmethod
    def from_orm(cls, obj):
        return cls(
            id=str(obj.id) if isinstance(obj.id, uuid.UUID) else obj.id,
            type=obj.type,
            title=obj.title,
            body=obj.body,
            payload=obj.payload,
            read=obj.read,
            created_at=obj.created_at,
        )
