from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserOut
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(dto: RegisterRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    try:
        result = await service.register(dto)
        return TokenResponse(
            token=result["token"],
            user=UserOut.model_validate(result["user"]),
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(dto: LoginRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    try:
        result = await service.login(dto)
        return TokenResponse(
            token=result["token"],
            user=UserOut.model_validate(result["user"]),
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
