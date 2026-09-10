from pydantic_settings import BaseSettings
from typing import List, Optional
import json


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/pethealth"

    # JWT
    secret_key: str = "super-secret-jwt-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days

    # AI Service
    ai_service_url: str = "http://localhost:8000/v1"
    ai_service_key: str = "dev-internal-key"

    # Cloud AI (Longcat / OpenAI-compatible)
    longcat_api_key: Optional[str] = None

    # Server
    host: str = "0.0.0.0"
    port: int = 8001
    log_level: str = "INFO"

    # CORS — allow all origins in development
    cors_origins: str = '["*"]'

    @property
    def cors_origin_list(self) -> List[str]:
        return json.loads(self.cors_origins)

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
