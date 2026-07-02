from pydantic import BaseModel
from typing import Optional, List


class FoodRecommendationRequest(BaseModel):
    pet_species: str
    pet_age: int
    pet_breed: Optional[str] = None
    health_conditions: Optional[List[str]] = None


class RecommendationItem(BaseModel):
    name: str
    reason: str
    type: str


class FoodRecommendationResponse(BaseModel):
    recommendations: List[RecommendationItem]
    reasoning: str
