"""
SQLAlchemy async engine and session factory.

Usage inside route handlers / services:

    async def my_route(db: AsyncSession = Depends(get_db)):
        result = await db.execute(select(MyModel))
        ...
"""

from __future__ import annotations

from collections.abc import AsyncGenerator
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

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


def _normalize_database_url(database_url: str) -> str:
    """
    Ensure we always use an async SQLAlchemy driver for Postgres.
    Accepts Supabase-style postgres/postgresql URLs and upgrades them.
    """
    if database_url.startswith("postgres://"):
        return "postgresql+asyncpg://" + database_url[len("postgres://") :]
    if database_url.startswith("postgresql://"):
        return "postgresql+asyncpg://" + database_url[len("postgresql://") :]
    if database_url.startswith("postgresql+psycopg2://"):
        return "postgresql+asyncpg://" + database_url[len("postgresql+psycopg2://") :]
    return database_url


def _ensure_asyncpg_pooler_compat(database_url: str) -> str:
    """
    Supabase transaction pooler (PgBouncer) is incompatible with asyncpg's
    prepared statement cache by default.
    """
    if not database_url.startswith("postgresql+asyncpg://"):
        return database_url
    if ".pooler.supabase.com" not in database_url:
        return database_url

    parts = urlsplit(database_url)
    query = dict(parse_qsl(parts.query, keep_blank_values=True))
    query.setdefault("prepared_statement_cache_size", "0")
    updated_query = urlencode(query)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, updated_query, parts.fragment))


async_engine = create_async_engine(
    _ensure_asyncpg_pooler_compat(_normalize_database_url(settings.DATABASE_URL)),
    **_engine_kwargs,
)

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
