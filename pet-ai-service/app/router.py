from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from typing import Optional

from app.models.requests import (
    SymptomAnalysisRequest, SymptomAnalysisResponse,
    EmergencyCheckRequest, EmergencyCheckResponse,
    ImageAnalysisRequest, ImageAnalysisResponse,
    RecommendationRequest, RecommendationResponse,
    KnowledgeQueryRequest, KnowledgeQueryResponse,
)
from app.services.symptom_analyzer import symptom_analyzer
from app.services.emergency_detector import emergency_detector
from app.services.recommendation_engine import recommendation_engine
from app.services.ai_router import ai_router, TaskDifficulty
from app.utils.deps import verify_api_key

router = APIRouter(prefix="/v1", dependencies=[Depends(verify_api_key)])


@router.get("/health")
async def health_check():
    from app.clients.ollama_client import OllamaClient
    from app.config import settings

    fast_ok = await OllamaClient(settings.fast_model).is_healthy()
    accurate_ok = await OllamaClient(settings.accurate_model).is_healthy()

    return {
        "status": "healthy" if fast_ok else "degraded",
        "models": {
            "fast": "loaded" if fast_ok else "unavailable",
            "accurate": "loaded" if accurate_ok else "unavailable",
        },
    }


@router.post("/symptoms/analyze", response_model=SymptomAnalysisResponse)
async def analyze_symptoms(req: SymptomAnalysisRequest):
    result = await symptom_analyzer.analyze(
        text=req.text,
        pet_species=req.pet_species,
        pet_age=req.pet_age,
        pet_breed=req.pet_breed,
        pet_weight_kg=req.pet_weight_kg,
    )
    return SymptomAnalysisResponse(**result)


@router.post("/symptoms/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_image(
    file: UploadFile = File(...),
    description: Optional[str] = Form(None),
):
    contents = await file.read()
    import base64
    image_b64 = base64.b64encode(contents).decode("utf-8")

    messages = [
        {
            "role": "system",
            "content": (
                "You are a veterinary vision AI. Analyze the pet image for visible symptoms "
                "like skin issues, eye problems, swelling, injuries, or abnormal posture. "
                "Respond in JSON:\n"
                '{"visible_symptoms": [...], "description": "...", '
                '"risk_indicators": [...], "recommendation": "..."}'
            ),
        },
        {
            "role": "user",
            "content": [
                {"type": "text", "text": f"Analyze this pet image. {description or ''}"},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}},
            ],
        },
    ]

    try:
        response = await ai_router.infer(
            messages=messages,
            task=TaskDifficulty.VISION,
            prefer_local=True,
            temperature=0.1,
        )
        import json
        from app.utils.parsers import extract_json_safe
        result = extract_json_safe(response)
        return ImageAnalysisResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image analysis failed: {str(e)}")


@router.post("/emergency/check", response_model=EmergencyCheckResponse)
async def check_emergency(req: EmergencyCheckRequest):
    result = await emergency_detector.check(
        symptoms=req.symptoms,
        pet_species=req.pet_species,
    )
    return EmergencyCheckResponse(**result)


@router.post("/recommendations/food", response_model=RecommendationResponse)
async def recommend_food(req: RecommendationRequest):
    result = await recommendation_engine.get_food_recommendation(
        pet_species=req.pet_species,
        pet_age=req.pet_age,
        pet_breed=req.pet_breed,
        health_conditions=req.health_conditions,
    )
    return RecommendationResponse(**result)


@router.post("/knowledge/query", response_model=KnowledgeQueryResponse)
async def query_knowledge(req: KnowledgeQueryRequest):
    from app.services.ai_router import ai_router
    from app.services.symptom_analyzer import symptom_analyzer

    messages = [
        {
            "role": "system",
            "content": (
                "You are a veterinary knowledge assistant. Answer pet health questions "
                "based on general veterinary knowledge. Be accurate and include disclaimers."
            ),
        },
        {"role": "user", "content": req.query},
    ]

    try:
        response = await ai_router.infer(
            messages=messages,
            task=TaskDifficulty.COMPLEX,
            temperature=0.2,
        )
        return KnowledgeQueryResponse(
            results=[{"source": "AI Knowledge", "content": response[:200]}],
            answer=response,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query failed: {str(e)}")
