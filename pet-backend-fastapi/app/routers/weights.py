import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.weight_record import WeightRecord
from app.schemas.weight_record import WeightRecordCreate, WeightRecordOut, WeightRecordList
from app.utils.security import get_current_user

router = APIRouter(prefix="/pets", tags=["Weight Records"])


@router.post("/{pet_id}/weights", response_model=WeightRecordOut, status_code=status.HTTP_201_CREATED)
async def create_weight_record(
    pet_id: str,
    dto: WeightRecordCreate,
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

    record = WeightRecord(
        pet_id=pet_uuid,
        weight_kg=dto.weight_kg,
        measured_at=dto.measured_at,
        notes=dto.notes,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return WeightRecordOut.model_validate(record)


@router.get("/{pet_id}/weights", response_model=WeightRecordList)
async def list_weight_records(
    pet_id: str,
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    from_date: str = Query(default=None, alias="from"),
    to_date: str = Query(default=None, alias="to"),
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

    query = select(WeightRecord).where(WeightRecord.pet_id == pet_uuid)

    if from_date:
        query = query.where(WeightRecord.measured_at >= from_date)
    if to_date:
        query = query.where(WeightRecord.measured_at <= to_date)

    query = query.order_by(WeightRecord.measured_at.desc())

    count_query = select(func.count()).select_from(query.subquery())
    count_result = await db.execute(count_query)
    total = count_result.scalar() or 0

    query = query.offset(offset).limit(limit)
    result = await db.execute(query)
    records = result.scalars().all()

    return WeightRecordList(
        records=[WeightRecordOut.model_validate(r) for r in records],
        total=total,
    )


@router.delete("/{pet_id}/weights/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_weight_record(
    pet_id: str,
    record_id: str,
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

    record_uuid = uuid.UUID(record_id)
    result = await db.execute(
        select(WeightRecord).where(
            WeightRecord.id == record_uuid,
            WeightRecord.pet_id == pet_uuid,
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Weight record not found")

    await db.delete(record)
    await db.commit()
