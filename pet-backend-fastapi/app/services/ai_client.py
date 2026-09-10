import json
import httpx
from typing import Optional
from loguru import logger

from app.config import settings

SYMPTOM_ANALYSIS_SYSTEM_PROMPT = """You are a veterinary AI assistant specialized in symptom analysis.
Analyze the given symptoms and pet information carefully.

Rules:
1. NEVER provide a definitive diagnosis — always phrase as "possible conditions"
2. Include a disclaimer that this is not a substitute for veterinary care
3. Flag any emergency symptoms immediately
4. Consider species-specific differences (dogs vs cats vs birds vs etc.)
5. Consider age and breed predispositions

Respond with valid JSON only (no markdown, no code fences):
{
  "risk_level": "low|medium|high|critical",
  "possible_conditions": ["condition 1", "condition 2"],
  "confidence": 0.0-1.0,
  "recommendation": "Clear actionable advice",
  "is_emergency": true/false,
  "emergency_actions": ["action 1", "action 2"]
}"""


class AIClient:
    def __init__(self):
        self.longcat_api_key = settings.longcat_api_key
        self.longcat_base_url = "https://api.longcat.chat/openai/v1"
        self.longcat_model = "LongCat-2.0"

    async def analyze_symptoms(self, text: str, **pet_info) -> dict:
        if not self.longcat_api_key:
            logger.error("LONGCAT_API_KEY not configured")
            return self._fallback("symptoms/analyze")

        context = (
            f"Species: {pet_info.get('pet_species') or 'Unknown'}, "
            f"Age: {pet_info.get('pet_age') or 'Unknown'}, "
            f"Breed: {pet_info.get('pet_breed') or 'Unknown'}, "
            f"Weight: {pet_info.get('pet_weight_kg') or 'Unknown'}kg"
        )

        messages = [
            {"role": "system", "content": SYMPTOM_ANALYSIS_SYSTEM_PROMPT},
            {"role": "user", "content": f"Pet Info: {context}\n\nSymptoms: {text}"},
        ]

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(
                    f"{self.longcat_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.longcat_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self.longcat_model,
                        "messages": messages,
                        "temperature": 0.1,
                        "max_tokens": 2048,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                content = data["choices"][0]["message"]["content"]
                return self._parse_llm_response(content)

        except httpx.TimeoutException:
            logger.error("Longcat API timeout")
        except httpx.HTTPStatusError as e:
            logger.error(f"Longcat API error {e.response.status_code}: {e.response.text[:200]}")
        except Exception as e:
            logger.error(f"Longcat API error: {e}")

        return self._fallback("symptoms/analyze")

    def _parse_llm_response(self, content: str) -> dict:
        try:
            text = content.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
            result = json.loads(text.strip())
            return {
                "risk_level": result.get("risk_level", "unknown"),
                "possible_conditions": result.get("possible_conditions", []),
                "confidence": result.get("confidence", 0.0),
                "recommendation": result.get("recommendation", ""),
                "is_emergency": result.get("is_emergency", False),
                "emergency_actions": result.get("emergency_actions"),
            }
        except (json.JSONDecodeError, KeyError, IndexError) as e:
            logger.warning(f"Failed to parse LLM response: {e}")
            return self._fallback("symptoms/analyze")

    async def check_emergency(self, symptoms: list, pet_species: str) -> dict:
        if not self.longcat_api_key:
            return self._fallback("emergency/check")

        messages = [
            {
                "role": "system",
                "content": (
                    "You are a veterinary emergency triage AI. "
                    "Given symptoms, determine if the pet needs immediate emergency care.\n\n"
                    "Known emergency red flags:\n"
                    "- Blue/pale gums\n- Seizures or collapse\n- Poison ingestion\n"
                    "- Difficulty breathing\n- Severe bleeding\n- Unable to stand\n"
                    "- Unconsciousness\n- Hit by car/trauma\n\n"
                    "Respond with JSON only:\n"
                    '{"is_emergency": true/false, "severity": "low|medium|high|critical", '
                    '"red_flags_detected": [...], "immediate_actions": [...], '
                    '"vet_required": true/false}'
                ),
            },
            {
                "role": "user",
                "content": f"Pet species: {pet_species}\nSymptoms: {', '.join(symptoms)}",
            },
        ]

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    f"{self.longcat_base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.longcat_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self.longcat_model,
                        "messages": messages,
                        "temperature": 0.1,
                        "max_tokens": 1024,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                content = data["choices"][0]["message"]["content"]
                return self._parse_llm_json(content)
        except Exception as e:
            logger.error(f"Longcat API emergency check error: {e}")
            return self._fallback("emergency/check")

    async def get_food_recommendation(self, **params) -> dict:
        return self._fallback("recommendations")

    async def get_image_analysis(self, image_base64: str, description: str = None) -> dict:
        return self._fallback("symptoms/analyze")

    async def query_knowledge(self, query: str) -> dict:
        return self._fallback("knowledge")

    def _parse_llm_json(self, text: str) -> dict:
        try:
            text = text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
            return json.loads(text.strip())
        except (json.JSONDecodeError, IndexError) as e:
            logger.warning(f"Failed to parse LLM JSON: {e}")
            return {}

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
