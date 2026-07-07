import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.symptom_record import SymptomRecord
from app.models.reminder import Reminder
from app.models.emergency_event import EmergencyEvent
from app.models.appointment import Appointment
from app.schemas.pet import PetCreate, PetUpdate, PetOut
from app.utils.security import get_current_user

router = APIRouter(prefix="/pets", tags=["Pets"])


@router.post("", response_model=PetOut, status_code=status.HTTP_201_CREATED)
async def create_pet(
    dto: PetCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_count_result = await db.execute(
        select(Pet).where(Pet.user_id == current_user.id)
    )
    pet_count = len(pet_count_result.scalars().all())

    if current_user.subscription_tier == "free" and pet_count >= 3:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Free tier limited to 3 pets. Upgrade to Premium for more.",
        )

    pet = Pet(user_id=current_user.id, **dto.model_dump())
    db.add(pet)
    await db.commit()
    await db.refresh(pet)
    return PetOut.model_validate(pet)


@router.get("", response_model=list[PetOut])
async def list_pets(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pet).where(Pet.user_id == current_user.id).order_by(Pet.created_at.desc())
    )
    pets = result.scalars().all()
    return [PetOut.model_validate(p) for p in pets]


@router.get("/{pet_id}", response_model=PetOut)
async def get_pet(
    pet_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_uuid = uuid.UUID(pet_id)
    result = await db.execute(
        select(Pet).where(Pet.id == pet_uuid, Pet.user_id == current_user.id)
    )
    pet = result.scalar_one_or_none()
    if not pet:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pet not found")
    return PetOut.model_validate(pet)


@router.put("/{pet_id}", response_model=PetOut)
async def update_pet(
    pet_id: str,
    dto: PetUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_uuid = uuid.UUID(pet_id)
    result = await db.execute(
        select(Pet).where(Pet.id == pet_uuid, Pet.user_id == current_user.id)
    )
    pet = result.scalar_one_or_none()
    if not pet:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pet not found")

    update_data = dto.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(pet, key, value)

    await db.commit()
    await db.refresh(pet)
    return PetOut.model_validate(pet)


@router.delete("/{pet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pet(
    pet_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_uuid = uuid.UUID(pet_id)

    result = await db.execute(
        select(Pet).where(Pet.id == pet_uuid, Pet.user_id == current_user.id)
    )
    pet = result.scalar_one_or_none()
    if not pet:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pet not found")

    for record in (await db.execute(
        select(SymptomRecord).where(SymptomRecord.pet_id == pet_uuid)
    )).scalars().all():
        await db.delete(record)

    for record in (await db.execute(
        select(Reminder).where(Reminder.pet_id == pet_uuid)
    )).scalars().all():
        await db.delete(record)

    for record in (await db.execute(
        select(EmergencyEvent).where(EmergencyEvent.pet_id == pet_uuid)
    )).scalars().all():
        await db.delete(record)

    for record in (await db.execute(
        select(Appointment).where(Appointment.pet_id == pet_uuid)
    )).scalars().all():
        await db.delete(record)

    await db.delete(pet)
    await db.commit()
