from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # AI Provider Keys
    openai_api_key: Optional[str] = None
    longcat_api_key: str = "ak_2In46X2Gp5hD8QO7vW5Vr5EU2ME2B"

    # Service
    ai_service_api_key: str = "dev-internal-key"
    host: str = "0.0.0.0"
    port: int = 8000
    log_level: str = "INFO"

    # Model names
    fast_model: str = "qwen2.5:1.5b-q4_K_M"
    accurate_model: str = "qwen2.5:7b-q4_K_M"
    vision_model: str = "qwen2.5-vl:7b-q4_K_M"
    embedding_model: str = "bge-m3:latest"

    # Ollama
    ollama_base_url: str = "http://ollama:11434"

    # Redis
    redis_url: str = "redis://redis:6379"

    # Database
    database_url: str = "postgresql://postgres:password@postgres:5432/pethealth"

    # NestJS
    nestjs_api_url: Optional[str] = None

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
