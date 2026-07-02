from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.recommendation import (
    FoodRecommendationRequest,
    FoodRecommendationResponse,
    RecommendationItem,
)
from app.utils.security import get_current_user
from app.services.ai_client import ai_client

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.post("/food", response_model=FoodRecommendationResponse)
async def recommend_food(
    dto: FoodRecommendationRequest,
    current_user: User = Depends(get_current_user),
):
    result = await ai_client.get_food_recommendation(
        pet_species=dto.pet_species,
        pet_age=dto.pet_age,
        pet_breed=dto.pet_breed,
        health_conditions=dto.health_conditions,
    )

    recommendations = [
        RecommendationItem(**item)
        for item in result.get("recommendations", [])
    ]

    return FoodRecommendationResponse(
        recommendations=recommendations,
        reasoning=result.get("reasoning", ""),
    )
