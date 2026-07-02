from typing import Optional, List
from loguru import logger

from app.services.ai_router import ai_router, TaskDifficulty
from app.clients.redis_cache import cache


FOOD_RULES = {
    "dog": {
        "puppy": "High-protein puppy food with DHA for brain development",
        "adult": "Balanced adult dog food with omega-3 for coat health",
        "senior": "Senior formula with joint support (glucosamine, chondroitin)",
    },
    "cat": {
        "kitten": "Kitten food with taurine for heart and eye health",
        "adult": "High-protein wet/dry mix for urinary tract health",
        "senior": "Senior cat food with easily digestible protein",
    },
}


class RecommendationEngine:
    async def get_food_recommendation(
        self,
        pet_species: str,
        pet_age: int,
        pet_breed: Optional[str] = None,
        health_conditions: Optional[List[str]] = None,
        prefer_local: bool = True,
    ) -> dict:
        age_group = "senior" if pet_age > 8 else ("puppy" if pet_age < 1 else "adult")
        if pet_species == "cat":
            age_group = "senior" if pet_age > 10 else ("kitten" if pet_age < 1 else "adult")

        base_rec = FOOD_RULES.get(pet_species, {}).get(age_group, "Standard diet")

        messages = [
            {
                "role": "system",
                "content": (
                    "You are a pet nutrition expert. Provide food and supplement recommendations. "
                    "Respond in JSON:\n"
                    '{"recommendations": [{"name": "...", "reason": "...", '
                    '"type": "food|supplement|treat"}], "reasoning": "..."}'
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Pet: {pet_species}, Age: {pet_age} years, Breed: {pet_breed or 'Mixed'}, "
                    f"Health issues: {', '.join(health_conditions) if health_conditions else 'None'}\n"
                    f"Base recommendation: {base_rec}\n"
                    f"Provide personalized food recommendations."
                ),
            },
        ]

        cache_key = f"food_rec:{pet_species}:{pet_age}:{pet_breed}:{health_conditions}"
        cached = await cache.get(cache_key)
        if cached:
            return cached

        try:
            response = await ai_router.infer(
                messages=messages,
                task=TaskDifficulty.SIMPLE,
                prefer_local=prefer_local,
                temperature=0.2,
            )
            import json
            result = json.loads(response.strip().replace("```json", "").replace("```", "").strip())
            result["base_guideline"] = base_rec
            await cache.set(cache_key, result, ttl=86400)
            return result
        except Exception as e:
            logger.error(f"Food recommendation failed: {e}")
            return {
                "recommendations": [{"name": base_rec, "reason": "Standard recommendation based on age/species", "type": "food"}],
                "reasoning": "AI unavailable, using rule-based fallback",
                "base_guideline": base_rec,
            }


recommendation_engine = RecommendationEngine()
