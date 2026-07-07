from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


_is_sqlite = settings.database_url.startswith("sqlite")

engine_kwargs = {
    "echo": settings.log_level == "DEBUG",
}
if _is_sqlite:
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20

engine = create_async_engine(settings.database_url, **engine_kwargs)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Migration: add notification_settings column to users table if missing
    if _is_sqlite:
        from sqlalchemy import text as sa_text
        async with engine.connect() as conn:
            result = await conn.execute(
                sa_text("PRAGMA table_info(users)")
            )
            columns = {row[1] for row in result.fetchall()}
            if "notification_settings" not in columns:
                from sqlalchemy import text as alter_text
                await conn.execute(
                    alter_text(
                        "ALTER TABLE users ADD COLUMN notification_settings JSON"
                    )
                )
                await conn.commit()


async def close_db():
    await engine.dispose()
