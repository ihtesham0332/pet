from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.appointment import Appointment
from app.schemas.veterinary import AppointmentCreate, AppointmentOut
from app.utils.security import get_current_user

router = APIRouter(prefix="/veterinary", tags=["Veterinary"])


@router.post("/appointments", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    dto: AppointmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_result = await db.execute(
        select(Pet).where(Pet.id == dto.pet_id, Pet.user_id == current_user.id)
    )
    if not pet_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Pet not found")

    appointment = Appointment(**dto.model_dump())
    db.add(appointment)
    await db.commit()
    await db.refresh(appointment)
    return AppointmentOut.model_validate(appointment)


@router.get("/appointments/my", response_model=list[AppointmentOut])
async def my_appointments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Appointment)
        .join(Pet)
        .where(Pet.user_id == current_user.id)
        .order_by(Appointment.scheduled_at.desc())
    )
    appointments = result.scalars().all()
    return [AppointmentOut.model_validate(a) for a in appointments]


@router.get("/appointments/pet/{pet_id}", response_model=list[AppointmentOut])
async def pet_appointments(
    pet_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pet_result = await db.execute(
        select(Pet).where(Pet.id == pet_id, Pet.user_id == current_user.id)
    )
    if not pet_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Pet not found")

    result = await db.execute(
        select(Appointment)
        .where(Appointment.pet_id == pet_id)
        .order_by(Appointment.scheduled_at.desc())
    )
    appointments = result.scalars().all()
    return [AppointmentOut.model_validate(a) for a in appointments]
