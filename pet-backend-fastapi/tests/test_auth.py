"""Test auth endpoints."""
from fastapi.testclient import TestClient
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app

client = TestClient(app)


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["service"] == "AI Pet Health Assistant API Gateway"


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_register_validation():
    resp = client.post("/auth/register", json={})
    assert resp.status_code == 422

    resp = client.post("/auth/register", json={
        "name": "Test User",
        "email": "invalid",
        "password": "123",
    })
    assert resp.status_code == 422


def test_login_validation():
    resp = client.post("/auth/login", json={"email": "test@test.com"})
    assert resp.status_code == 422
