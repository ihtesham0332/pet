import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.reminder import Reminder
from app.models.appointment import Appointment
from app.models.symptom_record import SymptomRecord
from app.models.emergency_event import EmergencyEvent
from app.utils.security import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary")
async def get_dashboard_summary(
    pet_id: str | None = Query(None, description="Scope summary to a specific pet"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if pet_id:
        pet_uuid = uuid.UUID(pet_id)
        result = await db.execute(
            select(Pet).where(Pet.id == pet_uuid, Pet.user_id == current_user.id)
        )
        if not result.scalar_one_or_none():
            return {"checkups": 0, "alerts": 0, "health_pct": 100, "vet_visits": 0}
        pet_ids = [pet_uuid]
    else:
        result = await db.execute(select(Pet.id).where(Pet.user_id == current_user.id))
        pet_ids = [row[0] for row in result.fetchall()]

    if not pet_ids:
        return {"checkups": 0, "alerts": 0, "health_pct": 100, "vet_visits": 0}

    checkups = 0
    result = await db.execute(
        select(func.count()).where(
            and_(
                Reminder.pet_id.in_(pet_ids),
                Reminder.reminder_type == "checkup",
                Reminder.status == "completed",
            )
        )
    )
    checkups += result.scalar() or 0

    result = await db.execute(
        select(func.count()).where(
            and_(
                Appointment.pet_id.in_(pet_ids),
                Appointment.status == "completed",
            )
        )
    )
    checkups += result.scalar() or 0

    alerts = 0
    result = await db.execute(
        select(func.count()).where(
            and_(
                EmergencyEvent.pet_id.in_(pet_ids),
                EmergencyEvent.status == "active",
            )
        )
    )
    alerts += result.scalar() or 0

    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(func.count()).where(
            and_(
                Reminder.pet_id.in_(pet_ids),
                Reminder.status == "pending",
                Reminder.scheduled_date < now,
            )
        )
    )
    alerts += result.scalar() or 0

    health_pct = 100.0
    ninety_days_ago = now - timedelta(days=90)
    result = await db.execute(
        select(func.count()).where(
            and_(
                SymptomRecord.pet_id.in_(pet_ids),
                SymptomRecord.created_at >= ninety_days_ago,
            )
        )
    )
    total_checks = result.scalar() or 0

    if total_checks > 0:
        result = await db.execute(
            select(func.count()).where(
                and_(
                    SymptomRecord.pet_id.in_(pet_ids),
                    SymptomRecord.created_at >= ninety_days_ago,
                    SymptomRecord.risk_level == "low",
                )
            )
        )
        low_risk = result.scalar() or 0
        health_pct = round((low_risk / total_checks) * 100)

    vet_visits = 0
    result = await db.execute(
        select(func.count()).where(Appointment.pet_id.in_(pet_ids))
    )
    vet_visits = result.scalar() or 0

    return {
        "checkups": checkups,
        "alerts": alerts,
        "health_pct": health_pct,
        "vet_visits": vet_visits,
    }
