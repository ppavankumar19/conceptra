"""
Tests for health endpoints.

GET /api/v1/health       – liveness probe
GET /api/v1/health/ready – readiness probe
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch


@pytest.mark.asyncio
async def test_health_liveness(client: AsyncClient) -> None:
    """GET /health returns 200 with status=ok."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert "timestamp" in body


@pytest.mark.asyncio
async def test_health_ready_ok(client: AsyncClient) -> None:
    """GET /health/ready returns 200 when DB and Redis are up."""
    # Redis is already mocked to ping=True in the client fixture.
    # SQLite DB should respond to SELECT 1 without issue.
    response = await client.get("/api/v1/health/ready")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ready"
    assert body["checks"]["database"] == "ok"
    assert body["checks"]["redis"] == "ok"


@pytest.mark.asyncio
async def test_health_ready_redis_down(client: AsyncClient) -> None:
    """GET /health/ready returns 503 when Redis is unavailable."""
    import app.services.cache as cache_module

    original_ping = cache_module.cache_service.ping
    cache_module.cache_service.ping = AsyncMock(return_value=False)

    try:
        response = await client.get("/api/v1/health/ready")
        assert response.status_code == 503
        body = response.json()
        assert "detail" in body
    finally:
        cache_module.cache_service.ping = original_ping
