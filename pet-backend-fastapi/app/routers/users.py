from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.schemas.auth import UserOut, UserUpdate
from app.utils.security import get_current_user
from app.utils.pagination import PaginationParams

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


@router.put("/me", response_model=UserOut)
async def update_me(
    dto: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if dto.name is not None:
        current_user.name = dto.name
    if dto.photo_url is not None:
        current_user.photo_url = dto.photo_url
    await db.commit()
    await db.refresh(current_user)
    return UserOut.model_validate(current_user)


@router.get("", response_model=dict)
async def list_users(
    pagination: PaginationParams = Depends(),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role != "admin":
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")

    result = await db.execute(select(User).offset(pagination.skip).limit(pagination.limit))
    users = result.scalars().all()
    total_result = await db.execute(select(User))
    total = len(total_result.scalars().all())

    return {
        "items": [UserOut.model_validate(u) for u in users],
        "total": total,
        "page": pagination.page,
        "limit": pagination.limit,
        "pages": (total + pagination.limit - 1) // pagination.limit,
    }
