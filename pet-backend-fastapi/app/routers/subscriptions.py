from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.schemas.subscription import SubscriptionStatus, UpgradeRequest, SubscriptionAction
from app.utils.security import get_current_user

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])

TIER_FEATURES = {
    "free": {
        "max_pets": 1,
        "symptom_checks_per_month": 3,
        "ai_analysis": True,
        "emergency_alerts": True,
        "telehealth": False,
        "weight_tracking": True,
        "reminder_system": True,
    },
    "premium": {
        "max_pets": 5,
        "symptom_checks_per_month": 30,
        "ai_analysis": True,
        "emergency_alerts": True,
        "telehealth": True,
        "weight_tracking": True,
        "reminder_system": True,
    },
    "pro": {
        "max_pets": 20,
        "symptom_checks_per_month": -1,
        "ai_analysis": True,
        "emergency_alerts": True,
        "telehealth": True,
        "weight_tracking": True,
        "reminder_system": True,
    },
}


@router.get("/status", response_model=SubscriptionStatus)
async def get_subscription_status(
    current_user: User = Depends(get_current_user),
):
    features = TIER_FEATURES.get(current_user.subscription_tier, TIER_FEATURES["free"])
    return SubscriptionStatus(
        tier=current_user.subscription_tier,
        status="active",
        started_at=current_user.created_at,
        features=features,
    )


@router.post("/upgrade", response_model=SubscriptionAction)
async def upgrade_subscription(
    dto: UpgradeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if dto.tier not in TIER_FEATURES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid tier. Choose 'premium' or 'pro'.",
        )
    if dto.tier == "free":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot 'upgrade' to free tier.",
        )

    current_user.subscription_tier = dto.tier
    await db.commit()
    return SubscriptionAction(
        detail=f"Upgraded to {dto.tier} successfully",
        success=True,
    )


@router.post("/cancel", response_model=SubscriptionAction)
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.subscription_tier == "free":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Already on free tier.",
        )

    current_user.subscription_tier = "free"
    await db.commit()
    return SubscriptionAction(
        detail="Subscription cancelled. Downgraded to free tier.",
        success=True,
    )
