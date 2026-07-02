from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.symptom_record import SymptomRecord
from app.models.emergency_event import EmergencyEvent
from app.utils.security import get_current_user

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard")
async def admin_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")

    total_users = await db.scalar(select(func.count(User.id)))
    total_pets = await db.scalar(select(func.count(Pet.id)))
    total_symptoms = await db.scalar(select(func.count(SymptomRecord.id)))
    total_emergencies = await db.scalar(
        select(func.count(EmergencyEvent.id)).where(EmergencyEvent.status == "active")
    )

    return {
        "total_users": total_users or 0,
        "total_pets": total_pets or 0,
        "total_symptoms_checked": total_symptoms or 0,
        "active_emergencies": total_emergencies or 0,
    }
