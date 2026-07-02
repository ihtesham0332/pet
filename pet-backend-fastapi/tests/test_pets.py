"""Test pet endpoints."""
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app

client = TestClient(app)


def test_pets_requires_auth():
    resp = client.get("/pets")
    assert resp.status_code == 403

    resp = client.post("/pets", json={"name": "Max", "species": "dog"})
    assert resp.status_code == 403
