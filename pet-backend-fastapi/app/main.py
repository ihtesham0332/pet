from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from loguru import logger

from app.config import settings
from app.database import init_db, close_db
from app.routers import auth, users, pets, symptoms, emergency, recommendations, veterinary, admin, reminders, subscriptions

from app.routers.auth_google import router as google_router
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title="AI Pet Health Assistant API",
        version="1.0.0",
        description="Backend API Gateway for the AI Pet Health Assistant Platform",
        routes=app.routes,
    )
    schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }
    for path in schema["paths"]:
        for method in schema["paths"][path]:
            schema["paths"][path][method].setdefault("security", [{"BearerAuth": []}])
    app.openapi_schema = schema
    return app.openapi_schema


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting Backend API — LogLevel: {settings.log_level}")
    try:
        await init_db()
        logger.info("Database tables created/verified")
    except Exception as e:
        logger.warning(f"Database init skipped (might already exist): {e}")
    yield
    await close_db()
    logger.info("Backend API shutting down")


app = FastAPI(
    title="AI Pet Health Assistant API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.openapi = custom_openapi

app.include_router(auth.router)
app.include_router(google_router)
app.include_router(users.router)
app.include_router(pets.router)
app.include_router(symptoms.router)
app.include_router(emergency.router)
app.include_router(recommendations.router)
app.include_router(veterinary.router)
app.include_router(admin.router)
app.include_router(reminders.router)
app.include_router(subscriptions.router)


@app.get("/")
async def root():
    return {
        "service": "AI Pet Health Assistant API Gateway",
        "version": "1.0.0",
        "docs": "/docs",
        "openapi": "/openapi.json",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "ai_service_url": settings.ai_service_url,
        "database": "sqlite",
    }
