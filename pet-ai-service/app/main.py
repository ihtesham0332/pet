from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.config import settings
from app.router import router
from app.clients.redis_cache import cache


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting AI Service — LogLevel: {settings.log_level}")
    await cache.connect()
    yield
    await cache.disconnect()
    logger.info("AI Service shutting down")


app = FastAPI(
    title="AI Pet Health Assistant — Local AI Service",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/")
async def root():
    return {
        "service": "AI Pet Health Assistant",
        "version": "1.0.0",
        "providers": ["local_qwen", "cloud_longcat", "cloud_openai"],
        "longcat_key_configured": bool(settings.longcat_api_key),
        "openai_key_configured": bool(settings.openai_api_key),
    }
