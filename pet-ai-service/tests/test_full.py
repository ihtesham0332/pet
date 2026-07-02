"""End-to-end test of the full API pipeline."""
import urllib.request
import json
import sys

BASE = "http://127.0.0.1:8000/v1"
HEADERS = {
    "X-API-Key": "dev-internal-key",
    "Content-Type": "application/json",
}


def test(name, method="POST", path="/symptoms/analyze", data=None):
    url = f"{BASE}{path}"
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=HEADERS, method=method)
    try:
        resp = urllib.request.urlopen(req, timeout=60)
        result = json.loads(resp.read())
        print(f"\n=== {name} ===")
        print(json.dumps(result, indent=2))
        return result
    except Exception as e:
        print(f"\n=== {name} FAILED ===")
        print(f"Error: {e}")
        return None


if __name__ == "__main__":
    print(f"Testing server at {BASE}")

    # 1. Health
    test("Health", "GET", "/health")

    # 2. Symptom Analysis (should use Longcat since Qwen is unavailable)
    r = test(
        "Symptom Analysis (Longcat fallback)",
        data={
            "text": "My 3-year-old Golden Retriever has a mild cough "
                    "and runny nose for 2 days. Still eating and playing.",
            "pet_species": "dog",
            "pet_age": 3,
            "pet_breed": "Golden Retriever",
            "pet_weight_kg": 32.5,
        },
    )
    if r:
        print(f"  -> AI Provider: {r.get('ai_provider', '?')}")
        print(f"  -> Risk Level: {r.get('risk_level', '?')}")
        print(f"  -> Emergency: {r.get('is_emergency', '?')}")

    # 3. Emergency Check
    test(
        "Emergency Check (rule-based)",
        data={
            "symptoms": ["my dog is having seizures", "blue gums"],
            "pet_species": "dog",
        },
    )

    # 4. Food Recommendation
    r = test(
        "Food Recommendation (Longcat)",
        path="/recommendations/food",
        data={
            "pet_species": "dog",
            "pet_age": 3,
            "pet_breed": "Golden Retriever",
            "health_conditions": ["sensitive stomach"],
        },
    )

    # 5. Image Analysis (should work via Longcat Vision)
    test(
        "Knowledge Query (Longcat)",
        path="/knowledge/query",
        data={"query": "What are signs of dehydration in dogs?"},
    )

    print("\n=== All tests complete ===")
