import httpx
from typing import Optional, List, Dict, Any
from tenacity import retry, stop_after_attempt, wait_exponential
from loguru import logger

from app.config import settings


class OllamaClient:
    def __init__(self, model_name: str, base_url: Optional[str] = None):
        self.model_name = model_name
        self.base_url = base_url or settings.ollama_base_url
        self.chat_url = f"{self.base_url}/api/chat"
        self.embed_url = f"{self.base_url}/api/embed"

    @retry(stop=stop_after_attempt(2), wait=wait_exponential(multiplier=1, min=1, max=3))
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.1,
        max_tokens: int = 2048,
        stream: bool = False,
    ) -> Dict[str, Any]:
        payload = {
            "model": self.model_name,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.post(self.chat_url, json=payload)
                response.raise_for_status()
                return response.json()
            except (httpx.TimeoutException, httpx.ConnectError):
                logger.error(f"Ollama unavailable for model {self.model_name}")
                raise
            except httpx.HTTPStatusError as e:
                logger.error(f"Ollama HTTP error: {e.response.status_code} - {e.response.text}")
                raise

    async def embed(self, text: str) -> List[float]:
        payload = {
            "model": self.embedding_model_name,
            "input": text,
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(self.embed_url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data.get("embeddings", [data.get("embedding", [])])[0]
            except Exception as e:
                logger.error(f"Embedding failed: {e}")
                raise

    @property
    def embedding_model_name(self) -> str:
        if "bge" in self.model_name.lower():
            return self.model_name
        return settings.embedding_model

    async def is_healthy(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(f"{self.base_url}/api/tags")
                return resp.status_code == 200
        except Exception:
            return False
