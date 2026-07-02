from pydantic import BaseModel
from typing import List, Optional


class EmergencyCheckRequest(BaseModel):
    symptoms: List[str]
    pet_id: str
    pet_species: str


class EmergencyCheckResponse(BaseModel):
    is_emergency: bool
    severity: str
    red_flags_detected: List[str]
    immediate_actions: List[str]
    vet_required: bool
