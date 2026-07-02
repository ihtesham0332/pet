import json
from typing import Optional, Tuple
from loguru import logger

from app.services.ai_router import ai_router, TaskDifficulty
from app.clients.redis_cache import cache
from app.prompts.symptom_prompts import SYMPTOM_ANALYSIS_SYSTEM_PROMPT


class SymptomAnalyzer:
    async def analyze(
        self,
        text: str,
        pet_species: Optional[str] = None,
        pet_age: Optional[int] = None,
        pet_breed: Optional[str] = None,
        pet_weight_kg: Optional[float] = None,
        prefer_local: bool = True,
    ) -> dict:
        cache_key = f"symptom:{hash(text)}:{pet_species}:{pet_age}"
        cached = await cache.get(cache_key)
        if cached:
            logger.info("Symptom analysis cache hit")
            return cached

        context = f"Species: {pet_species or 'Unknown'}, Age: {pet_age or 'Unknown'}, "
        context += f"Breed: {pet_breed or 'Unknown'}, Weight: {pet_weight_kg or 'Unknown'}kg"

        messages = [
            {"role": "system", "content": SYMPTOM_ANALYSIS_SYSTEM_PROMPT},
            {"role": "user", "content": f"Pet Info: {context}\n\nSymptoms: {text}"},
        ]

        try:
            difficulty = TaskDifficulty.SIMPLE if len(text) < 100 else TaskDifficulty.COMPLEX
            response = await ai_router.infer(
                messages=messages,
                task=difficulty,
                prefer_local=prefer_local,
                temperature=0.1,
            )

            result = self._parse_response(response)
            await cache.set(cache_key, result, ttl=1800)
            return result

        except Exception as e:
            logger.error(f"Symptom analysis failed: {e}")
            return {
                "risk_level": "unknown",
                "possible_conditions": ["Analysis unavailable"],
                "confidence": 0.0,
                "recommendation": "Unable to analyze symptoms. Please consult a veterinarian.",
                "is_emergency": False,
                "ai_provider": "none",
            }

    def _parse_response(self, response: str) -> dict:
        try:
            json_match = response.strip()
            if json_match.startswith("```"):
                json_match = json_match.split("```")[1]
                if json_match.startswith("json"):
                    json_match = json_match[4:]
            result = json.loads(json_match.strip())

            return {
                "risk_level": result.get("risk_level", "unknown"),
                "possible_conditions": result.get("possible_conditions", []),
                "confidence": result.get("confidence", 0.0),
                "recommendation": result.get("recommendation", ""),
                "is_emergency": result.get("is_emergency", False),
                "emergency_actions": result.get("emergency_actions"),
                "ai_provider": result.get("ai_provider", "local"),
            }
        except (json.JSONDecodeError, KeyError) as e:
            logger.warning(f"Failed to parse AI response as JSON: {e}")
            return {
                "risk_level": "unparsed",
                "possible_conditions": [],
                "confidence": 0.0,
                "recommendation": response[:500],
                "is_emergency": False,
                "ai_provider": "local",
            }


symptom_analyzer = SymptomAnalyzer()
