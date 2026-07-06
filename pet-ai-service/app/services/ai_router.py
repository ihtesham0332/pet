from enum import Enum
from loguru import logger

from app.clients.ollama_client import OllamaClient
from app.clients.cloud_ai_client import CloudAIClient
from app.config import settings


class AIProvider(str, Enum):
    LOCAL_QWEN_FAST = "local_qwen_fast"
    LOCAL_QWEN_ACCURATE = "local_qwen_accurate"
    LOCAL_QWEN_VISION = "local_qwen_vision"
    CLOUD_LONGCAT = "cloud_longcat"
    CLOUD_OPENAI = "cloud_openai"


class TaskDifficulty(str, Enum):
    SIMPLE = "simple"
    COMPLEX = "complex"
    VISION = "vision"


class AIRouter:
    def __init__(self):
        self._providers = {}
        self._initialize()

    def _initialize(self):
        try:
            self._providers[AIProvider.LOCAL_QWEN_FAST] = OllamaClient(
                model_name=settings.fast_model
            )
            self._providers[AIProvider.LOCAL_QWEN_ACCURATE] = OllamaClient(
                model_name=settings.accurate_model
            )
            self._providers[AIProvider.LOCAL_QWEN_VISION] = OllamaClient(
                model_name=settings.vision_model
            )
            self._providers[AIProvider.CLOUD_LONGCAT] = CloudAIClient(provider="longcat")
            if settings.openai_api_key:
                self._providers[AIProvider.CLOUD_OPENAI] = CloudAIClient(provider="openai")
            logger.info("AI Router initialized with {} providers", len(self._providers))
        except Exception as e:
            logger.error(f"AI Router init error: {e}")

    def _priority_chain(self, task: TaskDifficulty, prefer_local: bool) -> list[AIProvider]:
        if prefer_local:
            base = [
                AIProvider.LOCAL_QWEN_ACCURATE,
                AIProvider.LOCAL_QWEN_FAST,
                AIProvider.LOCAL_QWEN_VISION,
                AIProvider.CLOUD_LONGCAT,
                AIProvider.CLOUD_OPENAI,
            ]
            if task == TaskDifficulty.SIMPLE:
                base.insert(0, base.pop(base.index(AIProvider.LOCAL_QWEN_FAST)))
            elif task == TaskDifficulty.VISION:
                base.insert(0, base.pop(base.index(AIProvider.LOCAL_QWEN_VISION)))
        else:
            base = [
                AIProvider.CLOUD_LONGCAT,
                AIProvider.CLOUD_OPENAI,
                AIProvider.LOCAL_QWEN_ACCURATE,
                AIProvider.LOCAL_QWEN_FAST,
            ]

        return [p for p in base if p in self._providers]

    async def _skip_unhealthy(self, providers: list[AIProvider]) -> list[AIProvider]:
        healthy = []
        for key in providers:
            provider = self._providers.get(key)
            if isinstance(provider, OllamaClient):
                ok = await provider.is_healthy()
                if not ok:
                    logger.info("Skipping unhealthy Ollama provider: {}", key)
                    continue
            healthy.append(key)
        return healthy

    async def infer(
        self,
        messages: list,
        task: TaskDifficulty = TaskDifficulty.COMPLEX,
        prefer_local: bool = True,
        temperature: float = 0.1,
    ) -> str:
        priority = self._priority_chain(task, prefer_local)
        if not priority:
            raise RuntimeError("No AI provider available")
        priority = await self._skip_unhealthy(priority)

        last_error = None
        for provider_key in priority:
            provider = self._providers[provider_key]
            try:
                if isinstance(provider, OllamaClient):
                    response = await provider.chat(messages, temperature=temperature)
                    content = response.get("message", {}).get("content", "")
                elif isinstance(provider, CloudAIClient):
                    response = await provider.chat(messages, temperature=temperature)
                    content = response.get("choices", [{}])[0].get("message", {}).get("content", "")
                else:
                    continue

                logger.info("AI response from {}", provider_key)
                return content

            except Exception as e:
                logger.warning("Provider {} failed: {}", provider_key, str(e)[:100])
                last_error = e
                continue

        logger.error("All AI providers exhausted. Last error: {}", last_error)
        raise RuntimeError(f"All AI providers failed. Last error: {last_error}")

    def _get_available_fallback(self, prefer_local: bool, exclude: AIProvider = None) -> AIProvider:
        if prefer_local:
            candidates = [
                AIProvider.LOCAL_QWEN_ACCURATE,
                AIProvider.LOCAL_QWEN_FAST,
                AIProvider.CLOUD_LONGCAT,
                AIProvider.CLOUD_OPENAI,
            ]
        else:
            candidates = [
                AIProvider.CLOUD_LONGCAT,
                AIProvider.CLOUD_OPENAI,
                AIProvider.LOCAL_QWEN_ACCURATE,
            ]

        for c in candidates:
            if c != exclude and c in self._providers:
                return c
        return None


ai_router = AIRouter()
