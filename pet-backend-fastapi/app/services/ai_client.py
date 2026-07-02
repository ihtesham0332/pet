import httpx
from typing import Optional, Any
from loguru import logger

from app.config import settings


class AIClient:
    def __init__(self):
        self.base_url = settings.ai_service_url
        self.api_key = settings.ai_service_key
        self.headers = {
            "X-API-Key": self.api_key,
            "Content-Type": "application/json",
        }

    async def analyze_symptoms(self, text: str, **pet_info) -> dict:
        return await self._post("/symptoms/analyze", {"text": text, **pet_info})

    async def check_emergency(self, symptoms: list, pet_species: str) -> dict:
        return await self._post(
            "/emergency/check",
            {"symptoms": symptoms, "pet_species": pet_species},
        )

    async def get_food_recommendation(self, **params) -> dict:
        return await self._post("/recommendations/food", params)

    async def get_image_analysis(self, image_base64: str, description: str = None) -> dict:
        payload = {"image_base64": image_base64}
        if description:
            payload["description"] = description
        return await self._post("/symptoms/analyze-image", payload)

    async def query_knowledge(self, query: str) -> dict:
        return await self._post("/knowledge/query", {"query": query, "top_k": 5})

    async def _post(self, path: str, data: dict) -> dict:
        url = f"{self.base_url}{path}"
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(url, headers=self.headers, json=data)
                resp.raise_for_status()
                return resp.json()
        except httpx.TimeoutException:
            logger.error(f"AI Service timeout: {url}")
            return self._fallback(path)
        except httpx.HTTPStatusError as e:
            logger.error(f"AI Service error {e.response.status_code}: {e.response.text[:200]}")
            return self._fallback(path)
        except Exception as e:
            logger.error(f"AI Service error: {e}")
            return self._fallback(path)

    def _fallback(self, path: str) -> dict:
        if "symptoms/analyze" in path or "analyze-image" in path:
            return {
                "risk_level": "unknown",
                "possible_conditions": ["Service unavailable"],
                "confidence": 0.0,
                "recommendation": "AI analysis temporarily unavailable. Please consult a veterinarian.",
                "is_emergency": False,
            }
        if "emergency/check" in path:
            return {
                "is_emergency": False,
                "severity": "unknown",
                "red_flags_detected": [],
                "immediate_actions": ["Monitor symptoms", "Consult vet if concerned"],
                "vet_required": False,
            }
        if "recommendations" in path:
            return {"recommendations": [], "reasoning": "Service unavailable"}
        return {}


ai_client = AIClient()
