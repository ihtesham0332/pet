"""Test emergency endpoint."""
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app

client = TestClient(app)


def test_emergency_requires_auth():
    resp = client.post("/emergency/check", json={
        "symptoms": ["seizures"],
        "pet_id": "test",
        "pet_species": "dog",
    })
    assert resp.status_code == 403
