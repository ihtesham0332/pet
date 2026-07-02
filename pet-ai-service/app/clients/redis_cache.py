import json
from typing import Optional, Any
import redis.asyncio as redis
from loguru import logger

from app.config import settings


class RedisCache:
    def __init__(self):
        self._client: Optional[redis.Redis] = None

    async def connect(self):
        try:
            self._client = redis.from_url(
                settings.redis_url,
                decode_responses=True,
                socket_connect_timeout=3,
            )
            await self._client.ping()
            logger.info("Connected to Redis")
        except Exception as e:
            logger.warning(f"Redis unavailable, running without cache: {e}")
            self._client = None

    async def disconnect(self):
        if self._client:
            await self._client.aclose()

    async def get(self, key: str) -> Optional[Any]:
        if not self._client:
            return None
        try:
            data = await self._client.get(key)
            if data:
                return json.loads(data)
            return None
        except Exception as e:
            logger.warning(f"Redis get failed: {e}")
            return None

    async def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        if not self._client:
            return False
        try:
            await self._client.setex(key, ttl, json.dumps(value, default=str))
            return True
        except Exception as e:
            logger.warning(f"Redis set failed: {e}")
            return False

    async def delete(self, key: str) -> bool:
        if not self._client:
            return False
        try:
            return bool(await self._client.delete(key))
        except Exception:
            return False


cache = RedisCache()
