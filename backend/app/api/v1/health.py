"""
Health and readiness check endpoints.

GET /health       – liveness probe (always returns 200 if the process is alive)
GET /health/ready – readiness probe (checks DB + Redis; returns 503 on failure)
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.services.cache import cache_service

router = APIRouter(prefix="/health", tags=["health"])


@router.get("", summary="Liveness probe")
async def health_check() -> dict:
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/ready", summary="Readiness probe")
async def readiness_check(db: AsyncSession = Depends(get_db)) -> dict:
    """
    Returns 200 when both PostgreSQL and Redis are reachable.
    Returns 503 with a descriptive body on any connectivity failure.
    """
    results: dict[str, str] = {}
    failed = False

    # --- Database check ---
    try:
        await db.execute(text("SELECT 1"))
        results["database"] = "ok"
    except Exception as exc:
        results["database"] = f"error: {exc}"
        failed = True

    # --- Redis check ---
    redis_ok = await cache_service.ping()
    results["redis"] = "ok" if redis_ok else "error: ping failed"
    if not redis_ok:
        failed = True

    if failed:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "unavailable", "checks": results},
        )

    return {
        "status": "ready",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "checks": results,
    }
