"""
Tests for authentication endpoints.

GET /api/v1/auth/me  – auto-creates profile on first login
PUT /api/v1/auth/me  – updates mutable profile fields
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _mock_user(user_id: str = "test-uid", email: str = "student@test.com", role: str = "student"):
    return {"sub": user_id, "email": email, "role": role, "user_id": user_id}


# ---------------------------------------------------------------------------
# GET /auth/me
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_me_creates_profile_on_first_call(
    client: AsyncClient, app
) -> None:
    """First call to GET /auth/me should auto-create the user profile."""
    user_payload = _mock_user(user_id="new-user-001", email="newuser@test.com")

    app.dependency_overrides[get_current_user] = lambda: user_payload

    try:
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 200, response.text
        body = response.json()
        assert body["success"] is True
        data = body["data"]
        assert data["supabase_user_id"] == "new-user-001"
        assert data["email"] == "newuser@test.com"
        assert data["role"] == "student"
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_get_me_returns_existing_profile(
    client: AsyncClient, app
) -> None:
    """Subsequent calls to GET /auth/me should return the same profile."""
    user_payload = _mock_user(user_id="existing-user-001", email="existing@test.com")

    app.dependency_overrides[get_current_user] = lambda: user_payload

    try:
        # First call – creates
        r1 = await client.get("/api/v1/auth/me")
        assert r1.status_code == 200
        id1 = r1.json()["data"]["id"]

        # Second call – fetches existing
        r2 = await client.get("/api/v1/auth/me")
        assert r2.status_code == 200
        id2 = r2.json()["data"]["id"]

        assert id1 == id2  # Same profile returned both times
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_get_me_requires_auth(client: AsyncClient) -> None:
    """GET /auth/me without Authorization header should return 401."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# PUT /auth/me
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_update_me_display_name(client: AsyncClient, app) -> None:
    """PUT /auth/me should update display_name."""
    user_payload = _mock_user(user_id="update-user-001", email="updateme@test.com")
    app.dependency_overrides[get_current_user] = lambda: user_payload

    try:
        # Ensure profile exists
        await client.get("/api/v1/auth/me")

        response = await client.put(
            "/api/v1/auth/me",
            json={"display_name": "Ravi Kumar"},
        )
        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data["display_name"] == "Ravi Kumar"
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_update_me_grade(client: AsyncClient, app) -> None:
    """PUT /auth/me should update class_grade."""
    user_payload = _mock_user(user_id="grade-user-001", email="grade@test.com")
    app.dependency_overrides[get_current_user] = lambda: user_payload

    try:
        await client.get("/api/v1/auth/me")

        response = await client.put(
            "/api/v1/auth/me",
            json={"class_grade": 9, "preferred_language": "hi"},
        )
        assert response.status_code == 200, response.text
        data = response.json()["data"]
        assert data["class_grade"] == 9
        assert data["preferred_language"] == "hi"
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_update_me_invalid_grade(client: AsyncClient, app) -> None:
    """class_grade outside 6-12 range should return 422."""
    user_payload = _mock_user(user_id="invalid-grade-user", email="invalid@test.com")
    app.dependency_overrides[get_current_user] = lambda: user_payload

    try:
        response = await client.put(
            "/api/v1/auth/me",
            json={"class_grade": 5},  # Below minimum
        )
        assert response.status_code == 422
    finally:
        app.dependency_overrides.pop(get_current_user, None)
