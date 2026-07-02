from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.emergency_event import EmergencyEvent
from app.schemas.emergency import EmergencyCheckRequest, EmergencyCheckResponse
from app.utils.security import get_current_user
from app.services.ai_client import ai_client

router = APIRouter(prefix="/emergency", tags=["Emergency"])


@router.post("/check", response_model=EmergencyCheckResponse)
async def check_emergency(
    dto: EmergencyCheckRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_result = await db.execute(
        select(Pet).where(Pet.id == dto.pet_id, Pet.user_id == current_user.id)
    )
    if not pet_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Pet not found")

    result = await ai_client.check_emergency(dto.symptoms, dto.pet_species)

    if result.get("is_emergency", False):
        event = EmergencyEvent(
            pet_id=dto.pet_id,
            severity=result.get("severity", "unknown"),
            red_flags=result.get("red_flags_detected", []),
            action_taken="; ".join(result.get("immediate_actions", [])),
        )
        db.add(event)
        await db.commit()

    return EmergencyCheckResponse(
        is_emergency=result.get("is_emergency", False),
        severity=result.get("severity", "unknown"),
        red_flags_detected=result.get("red_flags_detected", []),
        immediate_actions=result.get("immediate_actions", ["Monitor symptoms"]),
        vet_required=result.get("vet_required", False),
    )
