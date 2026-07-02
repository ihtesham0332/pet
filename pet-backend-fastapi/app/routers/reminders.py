import uuid

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_

from app.database import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.reminder import Reminder
from app.schemas.reminder import ReminderCreate, ReminderUpdate, ReminderOut, ReminderList
from app.utils.security import get_current_user

router = APIRouter(prefix="/reminders", tags=["Reminders"])


@router.get("", response_model=ReminderList)
async def list_reminders(
    status_filter: str | None = Query(None, alias="status"),
    reminder_type: str | None = Query(None, alias="type"),
    upcoming: bool = Query(False, description="Only return upcoming (pending) reminders ordered by date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        query = select(Reminder).where(Reminder.user_id == current_user.id)

        if status_filter:
            query = query.where(Reminder.status == status_filter)
        if reminder_type:
            query = query.where(Reminder.reminder_type == reminder_type)
        if upcoming:
            query = query.where(Reminder.status == "pending").order_by(Reminder.scheduled_date.asc())
        else:
            query = query.order_by(Reminder.created_at.desc())

        result = await db.execute(query)
        reminders = result.scalars().all()
        return ReminderList(
            reminders=[ReminderOut.model_validate(r) for r in reminders],
            total=len(reminders),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch reminders: {str(e)}",
        )


@router.post("", response_model=ReminderOut, status_code=status.HTTP_201_CREATED)
async def create_reminder(
    dto: ReminderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        if dto.pet_id:
            pet_result = await db.execute(
                select(Pet).where(Pet.id == dto.pet_id, Pet.user_id == current_user.id)
            )
            if not pet_result.scalar_one_or_none():
                raise HTTPException(status_code=404, detail="Pet not found")

        reminder = Reminder(
            user_id=current_user.id,
            pet_id=uuid.UUID(dto.pet_id) if dto.pet_id else None,
            title=dto.title,
            description=dto.description,
            reminder_type=dto.reminder_type,
            scheduled_date=dto.scheduled_date,
        )
        db.add(reminder)
        await db.commit()
        await db.refresh(reminder)
        return ReminderOut.model_validate(reminder)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create reminder: {str(e)}",
        )


@router.get("/{reminder_id}", response_model=ReminderOut)
async def get_reminder(
    reminder_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await db.execute(
            select(Reminder).where(Reminder.id == uuid.UUID(reminder_id), Reminder.user_id == current_user.id)
        )
        reminder = result.scalar_one_or_none()
        if not reminder:
            raise HTTPException(status_code=404, detail="Reminder not found")
        return ReminderOut.model_validate(reminder)
    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid reminder ID format")
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch reminder: {str(e)}",
        )


@router.put("/{reminder_id}", response_model=ReminderOut)
async def update_reminder(
    reminder_id: str,
    dto: ReminderUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await db.execute(
            select(Reminder).where(Reminder.id == uuid.UUID(reminder_id), Reminder.user_id == current_user.id)
        )
        reminder = result.scalar_one_or_none()
        if not reminder:
            raise HTTPException(status_code=404, detail="Reminder not found")

        update_data = dto.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if key == "pet_id" and value is not None:
                value = uuid.UUID(value)
            setattr(reminder, key, value)

        await db.commit()
        await db.refresh(reminder)
        return ReminderOut.model_validate(reminder)
    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid reminder ID format")
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update reminder: {str(e)}",
        )


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    reminder_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await db.execute(
            select(Reminder).where(Reminder.id == uuid.UUID(reminder_id), Reminder.user_id == current_user.id)
        )
        reminder = result.scalar_one_or_none()
        if not reminder:
            raise HTTPException(status_code=404, detail="Reminder not found")

        await db.delete(reminder)
        await db.commit()
    except HTTPException:
        raise
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid reminder ID format")
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete reminder: {str(e)}",
        )
