"""
SQLAlchemy async engine and session factory.

Usage inside route handlers / services:

    async def my_route(db: AsyncSession = Depends(get_db)):
        result = await db.execute(select(MyModel))
        ...
"""

from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from app.core.config import settings

# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------

# NullPool is safe for async; avoids connection issues across event-loop restarts
# in development.  Use a pooled engine in production by removing pool_class.
_engine_kwargs: dict = {
    "echo": not settings.IS_PRODUCTION,
    "future": True,
}

if settings.IS_TESTING:
    # Tests use aiosqlite – NullPool prevents cross-task connection reuse
    _engine_kwargs["poolclass"] = NullPool

async_engine = create_async_engine(settings.DATABASE_URL, **_engine_kwargs)

# ---------------------------------------------------------------------------
# Session factory
# ---------------------------------------------------------------------------

AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


# ---------------------------------------------------------------------------
# FastAPI dependency
# ---------------------------------------------------------------------------


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Yield an AsyncSession for the duration of a single HTTP request.
    Automatically commits on success and rolls back on exception.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
