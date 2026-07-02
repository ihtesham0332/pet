import json
import re
from typing import Any, Dict


def extract_json(text: str) -> Dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    text = text.strip()
    return json.loads(text)


def extract_json_safe(text: str) -> Dict[str, Any]:
    try:
        return extract_json(text)
    except (json.JSONDecodeError, IndexError):
        pass
    try:
        brace_start = text.index("{")
        brace_end = text.rindex("}") + 1
        return json.loads(text[brace_start:brace_end])
    except (ValueError, json.JSONDecodeError):
        return {"raw_text": text[:500], "parsed": False}


def extract_risk_level(text: str) -> str:
    keywords = {"critical": "critical", "high": "high", "medium": "medium", "low": "low"}
    text_lower = text.lower()
    for keyword, level in keywords.items():
        if keyword in text_lower:
            return level
    return "unknown"
