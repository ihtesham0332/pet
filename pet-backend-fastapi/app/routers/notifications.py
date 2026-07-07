import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification import (
    NotificationSettingsIn,
    NotificationSettingsOut,
    NotificationOut,
)
from app.utils.security import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/settings", response_model=NotificationSettingsOut)
async def get_settings(
    current_user: User = Depends(get_current_user),
):
    settings = current_user.notification_settings or {}
    return NotificationSettingsOut(
        push_enabled=settings.get("push_enabled", True),
        email_enabled=settings.get("email_enabled", True),
        appointment_reminders=settings.get("appointment_reminders", True),
        vaccination_reminders=settings.get("vaccination_reminders", True),
        checkup_reminders=settings.get("checkup_reminders", True),
        symptom_alerts=settings.get("symptom_alerts", True),
        emergency_alerts=settings.get("emergency_alerts", True),
    )


@router.put("/settings", response_model=NotificationSettingsOut)
async def update_settings(
    dto: NotificationSettingsIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current = current_user.notification_settings or {}
    for key, value in dto.model_dump(exclude_none=True).items():
        current[key] = value
    current_user.notification_settings = current
    await db.commit()
    await db.refresh(current_user)
    return NotificationSettingsOut(**current)


@router.get("", response_model=list[NotificationOut])
async def list_notifications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
    )
    return [NotificationOut.from_orm(n) for n in result.scalars().all()]


@router.get("/unread-count")
async def unread_count(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(func.count(Notification.id)).where(
            Notification.user_id == current_user.id,
            Notification.read == False,
        )
    )
    return {"count": result.scalar() or 0}


@router.put("/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    notif_uuid = uuid.UUID(notification_id)
    result = await db.execute(
        select(Notification).where(
            Notification.id == notif_uuid,
            Notification.user_id == current_user.id,
        )
    )
    notif = result.scalar_one_or_none()
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    notif.read = True
    await db.commit()


@router.put("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id, Notification.read == False)
    )
    await db.execute(
        Notification.__table__.update()
        .where(Notification.user_id == current_user.id)
        .values(read=True)
    )
    await db.commit()
