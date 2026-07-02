import pytest
from app.config import settings


@pytest.fixture(autouse=True)
def test_settings():
    settings.log_level = "DEBUG"
    settings.ai_service_api_key = "test-key"
    yield
