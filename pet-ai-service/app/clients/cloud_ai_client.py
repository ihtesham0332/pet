import httpx
from typing import Optional, List, Dict, Any
from tenacity import retry, stop_after_attempt, wait_exponential
from loguru import logger

from app.config import settings


class CloudAIClient:
    """OpenAI-compatible client for Longcat and OpenAI APIs."""

    def __init__(self, provider: str = "longcat"):
        self.provider = provider

        if provider == "longcat":
            self.api_key = settings.longcat_api_key
            self.base_url = "https://api.longcat.chat/openai"
            self.model = "LongCat-2.0-Preview"
        elif provider == "openai":
            self.api_key = settings.openai_api_key or ""
            self.base_url = "https://api.openai.com/v1"
            self.model = "gpt-4o-mini"
        else:
            raise ValueError(f"Unknown provider: {provider}")

    @retry(stop=stop_after_attempt(2), wait=wait_exponential(multiplier=1, min=1, max=5))
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=headers,
                    json=payload,
                )
                response.raise_for_status()
                return response.json()
            except httpx.TimeoutException:
                logger.error(f"{self.provider} timeout")
                raise
            except httpx.HTTPStatusError as e:
                logger.error(f"{self.provider} error: {e.response.status_code} - {e.response.text[:200]}")
                raise

    async def is_healthy(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self.base_url}/models",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                )
                return resp.status_code == 200
        except Exception:
            return False
