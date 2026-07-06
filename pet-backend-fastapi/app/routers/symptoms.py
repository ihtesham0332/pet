import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.symptom_record import SymptomRecord
from app.schemas.symptom import SymptomAnalyzeRequest, SymptomAnalyzeResponse, SymptomRecordOut
from app.utils.security import get_current_user
from app.services.ai_client import ai_client

router = APIRouter(prefix="/symptoms", tags=["Symptoms"])


@router.post("/analyze", response_model=SymptomAnalyzeResponse)
async def analyze_symptoms(
    dto: SymptomAnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_id = uuid.UUID(dto.pet_id)
    pet_result = await db.execute(
        select(Pet).where(Pet.id == pet_id, Pet.user_id == current_user.id)
    )
    pet = pet_result.scalar_one_or_none()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    ai_result = await ai_client.analyze_symptoms(
        text=dto.text,
        pet_species=dto.pet_species or pet.species,
        pet_age=dto.pet_age,
        pet_breed=dto.pet_breed or pet.breed,
        pet_weight_kg=dto.pet_weight_kg or (float(pet.weight_kg) if pet.weight_kg else None),
    )

    record = SymptomRecord(
        pet_id=pet_id,
        symptoms_text=dto.text,
        ai_diagnosis=ai_result,
        risk_level=ai_result.get("risk_level"),
        is_emergency=ai_result.get("is_emergency", False),
    )
    db.add(record)
    await db.commit()

    return SymptomAnalyzeResponse(
        risk_level=ai_result.get("risk_level", "unknown"),
        possible_conditions=ai_result.get("possible_conditions", []),
        confidence=ai_result.get("confidence", 0.0),
        recommendation=ai_result.get("recommendation", ""),
        is_emergency=ai_result.get("is_emergency", False),
        emergency_actions=ai_result.get("emergency_actions"),
    )


@router.get("/pet/{pet_id}", response_model=list[SymptomRecordOut])
async def symptom_history(
    pet_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_uuid = uuid.UUID(pet_id)
    pet_result = await db.execute(
        select(Pet).where(Pet.id == pet_uuid, Pet.user_id == current_user.id)
    )
    if not pet_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Pet not found")

    result = await db.execute(
        select(SymptomRecord)
        .where(SymptomRecord.pet_id == pet_uuid)
        .order_by(SymptomRecord.created_at.desc())
    )
    records = result.scalars().all()
    return [SymptomRecordOut.model_validate(r) for r in records]
