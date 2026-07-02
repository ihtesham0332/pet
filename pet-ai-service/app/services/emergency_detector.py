from typing import List
from loguru import logger

from app.services.ai_router import ai_router, TaskDifficulty


RED_FLAG_SYMPTOMS = {
    "blue gums": {"severity": "critical", "action": "Immediate veterinary emergency"},
    "seizures": {"severity": "critical", "action": "Emergency vet visit required"},
    "poison": {"severity": "critical", "action": "Call pet poison control immediately"},
    "difficulty breathing": {"severity": "critical", "action": "Emergency oxygen required"},
    "unconscious": {"severity": "critical", "action": "CPR may be needed, rush to vet"},
    "severe bleeding": {"severity": "critical", "action": "Apply pressure, emergency vet"},
    "hit by car": {"severity": "critical", "action": "Immobilize, emergency transport"},
    "unable to stand": {"severity": "high", "action": "Veterinary visit within 1 hour"},
    "vomiting blood": {"severity": "high", "action": "Veterinary visit within 1 hour"},
    "blood in urine": {"severity": "high", "action": "Veterinary visit within 24 hours"},
    "not eating 2 days": {"severity": "high", "action": "Veterinary visit within 24 hours"},
    "eye injury": {"severity": "high", "action": "Veterinary visit within 2 hours"},
    "broken bone": {"severity": "high", "action": "Immobilize, vet within 2 hours"},
    "heat stroke": {"severity": "critical", "action": "Cool down gradually, emergency vet"},
    "snake bite": {"severity": "critical", "action": "Keep calm, emergency antivenom"},
}


class EmergencyDetector:
    def __init__(self):
        self.red_flags = {k.lower(): v for k, v in RED_FLAG_SYMPTOMS.items()}

    async def check(self, symptoms: List[str], pet_species: str) -> dict:
        symptom_text = " ".join(s.lower() for s in symptoms)

        rule_matches = []
        for keyword, info in self.red_flags.items():
            if keyword in symptom_text:
                rule_matches.append({"keyword": keyword, **info})

        if rule_matches:
            logger.warning(f"Emergency red flags detected: {[m['keyword'] for m in rule_matches]}")
            return {
                "is_emergency": True,
                "severity": max(m["severity"] for m in rule_matches),
                "red_flags_detected": [m["keyword"] for m in rule_matches],
                "immediate_actions": list(set(m["action"] for m in rule_matches)),
                "vet_required": True,
                "detection_method": "rule_based",
            }

        ai_result = await self._ai_check(symptom_text, pet_species)
        return ai_result

    async def _ai_check(self, symptom_text: str, pet_species: str) -> dict:
        messages = [
            {
                "role": "system",
                "content": (
                    "You are a veterinary emergency triage AI. Given symptoms, determine "
                    "if the pet needs emergency care. Respond in JSON:\n"
                    '{"is_emergency": bool, "severity": "low|medium|high|critical", '
                    '"red_flags_detected": [...], "immediate_actions": [...], '
                    '"vet_required": bool}'
                ),
            },
            {
                "role": "user",
                "content": f"Pet species: {pet_species}\nSymptoms: {symptom_text}\nIs this an emergency?",
            },
        ]

        try:
            response = await ai_router.infer(
                messages=messages,
                task=TaskDifficulty.COMPLEX,
                prefer_local=True,
                temperature=0.05,
            )
            import json
            result = json.loads(response.strip().replace("```json", "").replace("```", "").strip())
            result["detection_method"] = "ai_enhanced"
            return result
        except Exception as e:
            logger.error(f"AI emergency check failed: {e}")
            return {
                "is_emergency": False,
                "severity": "unknown",
                "red_flags_detected": [],
                "immediate_actions": ["Monitor symptoms", "Consult vet if concerned"],
                "vet_required": False,
                "detection_method": "failed",
            }


emergency_detector = EmergencyDetector()
