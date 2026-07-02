from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum


class TaskType(str, Enum):
    SYMPTOM_ANALYSIS = "symptom_analysis"
    RISK_CLASSIFICATION = "risk_classification"
    EMERGENCY_CHECK = "emergency_check"
    FOOD_RECOMMENDATION = "food_recommendation"
    PRODUCT_RECOMMENDATION = "product_recommendation"
    KNOWLEDGE_QUERY = "knowledge_query"
    IMAGE_ANALYSIS = "image_analysis"


class SymptomAnalysisRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=5000)
    pet_species: Optional[str] = None
    pet_age: Optional[int] = None
    pet_breed: Optional[str] = None
    pet_weight_kg: Optional[float] = None


class SymptomAnalysisResponse(BaseModel):
    risk_level: str
    possible_conditions: List[str]
    confidence: float
    recommendation: str
    is_emergency: bool
    emergency_actions: Optional[List[str]] = None
    ai_provider: str = "local"


class EmergencyCheckRequest(BaseModel):
    symptoms: List[str]
    pet_species: str
    pet_age: Optional[int] = None


class EmergencyCheckResponse(BaseModel):
    is_emergency: bool
    severity: str
    red_flags_detected: List[str]
    immediate_actions: List[str]
    vet_required: bool


class ImageAnalysisRequest(BaseModel):
    image_base64: str
    description: Optional[str] = None


class ImageAnalysisResponse(BaseModel):
    visible_symptoms: List[str]
    description: str
    risk_indicators: List[str]
    recommendation: str


class RecommendationRequest(BaseModel):
    pet_species: str
    pet_age: int
    pet_breed: Optional[str] = None
    health_conditions: Optional[List[str]] = None
    preference: Optional[str] = None


class RecommendationResponse(BaseModel):
    recommendations: List[dict]
    reasoning: str


class KnowledgeQueryRequest(BaseModel):
    query: str
    top_k: int = 5


class KnowledgeQueryResponse(BaseModel):
    results: List[dict]
    answer: str
