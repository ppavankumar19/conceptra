"""
Pytest configuration and shared fixtures for the EduViz test suite.

Test database: SQLite in-memory (via aiosqlite) to avoid requiring
a live PostgreSQL instance during CI.

JWT authentication: uses a fake HS256 token signed with a known secret.
"""

from __future__ import annotations

import os
from collections.abc import AsyncGenerator
from typing import Any
from unittest.mock import AsyncMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

# ---------------------------------------------------------------------------
# Set test environment BEFORE importing app modules
# ---------------------------------------------------------------------------
os.environ.setdefault("ENVIRONMENT", "testing")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("SUPABASE_URL", "https://test.supabase.co")
os.environ.setdefault("SUPABASE_JWT_SECRET", "test-secret-key-for-testing-only")
os.environ.setdefault("SUPABASE_ANON_KEY", "test-anon-key")
os.environ.setdefault("SECRET_KEY", "test-secret-key")
os.environ.setdefault("ALLOWED_ORIGINS", "http://localhost:3000")

from app.db.models import Base
from app.db.session import get_db


# ---------------------------------------------------------------------------
# In-memory SQLite engine (shared across the test session)
# ---------------------------------------------------------------------------

_TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

_engine = create_async_engine(
    _TEST_DB_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestSessionLocal = async_sessionmaker(
    bind=_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


# ---------------------------------------------------------------------------
# Session-scoped: create tables once
# ---------------------------------------------------------------------------


@pytest_asyncio.fixture(scope="session", autouse=True)
async def _create_tables():
    """Create all tables in the in-memory SQLite DB at the start of the test session."""
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


# ---------------------------------------------------------------------------
# Function-scoped DB session (rolls back after each test)
# ---------------------------------------------------------------------------


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with _TestSessionLocal() as session:
        try:
            yield session
        finally:
            await session.rollback()


# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session")
def app():
    """Return the FastAPI application with migrations skipped."""
    # Patch lifespan to skip Alembic migrations and seeding in tests
    from unittest.mock import AsyncMock, patch

    from app.main import create_app

    # We create the app without triggering the real lifespan
    from fastapi import FastAPI
    from contextlib import asynccontextmanager

    @asynccontextmanager
    async def _noop_lifespan(app):
        yield

    import app.main as main_module

    original_lifespan = main_module.lifespan
    main_module.lifespan = _noop_lifespan

    _app = create_app()

    main_module.lifespan = original_lifespan
    return _app


# ---------------------------------------------------------------------------
# Async HTTP client
# ---------------------------------------------------------------------------


@pytest_asyncio.fixture
async def client(app, db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """
    AsyncClient wired to the test FastAPI app.

    Overrides the get_db dependency to use the test SQLite session.
    """

    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db

    # Patch Redis cache to a no-op so tests don't need a real Redis
    with patch("app.services.cache.cache_service") as mock_cache:
        mock_cache.get = AsyncMock(return_value=None)
        mock_cache.set = AsyncMock(return_value=None)
        mock_cache.delete = AsyncMock(return_value=None)
        mock_cache.delete_pattern = AsyncMock(return_value=0)
        mock_cache.ping = AsyncMock(return_value=True)

        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as ac:
            yield ac

    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# JWT fixtures
# ---------------------------------------------------------------------------

_TEST_USER_ID = "test-supabase-uid-123"
_TEST_USER_EMAIL = "student@test.com"
_TEST_JWT_SECRET = "test-secret-key-for-testing-only"


@pytest.fixture
def mock_jwt_payload() -> dict[str, Any]:
    """Return a fake decoded JWT payload for a student user."""
    return {
        "sub": _TEST_USER_ID,
        "email": _TEST_USER_EMAIL,
        "role": "student",
        "user_id": _TEST_USER_ID,
    }


@pytest.fixture
def mock_jwt_payload_admin() -> dict[str, Any]:
    return {
        "sub": "admin-supabase-uid-456",
        "email": "admin@test.com",
        "role": "admin",
        "user_id": "admin-supabase-uid-456",
    }


def _make_token(payload: dict[str, Any]) -> str:
    """Sign a JWT with the test HS256 secret."""
    from jose import jwt

    return jwt.encode(payload, _TEST_JWT_SECRET, algorithm="HS256")


@pytest.fixture
def auth_headers(mock_jwt_payload: dict[str, Any]) -> dict[str, str]:
    """Authorization header for a regular student."""
    token = _make_token(mock_jwt_payload)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def auth_headers_admin(mock_jwt_payload_admin: dict[str, Any]) -> dict[str, str]:
    """Authorization header for an admin user."""
    token = _make_token(mock_jwt_payload_admin)
    return {"Authorization": f"Bearer {token}"}
