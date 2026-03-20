"""
Analytics endpoints (teacher/admin only).

GET /analytics/summary               – overall platform stats
GET /analytics/module/{module_id}    – per-module stats
GET /analytics/user/{user_id}        – per-student analytics
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_teacher
from app.db.models import SimulationModule, SimulationSession, UserProfile
from app.db.session import get_db

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/summary")
async def analytics_summary(
    user: dict[str, Any] = Depends(require_teacher),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Overall platform statistics:
    - total registered users
    - total simulation sessions
    - sessions per day for the last 7 days
    """
    total_users: int = (
        await db.execute(select(func.count(UserProfile.id)))
    ).scalar_one()

    total_sessions: int = (
        await db.execute(select(func.count(SimulationSession.id)))
    ).scalar_one()

    # Sessions per day for the last 7 days
    now = datetime.now(timezone.utc)
    seven_days_ago = now - timedelta(days=7)

    sessions_per_day_result = await db.execute(
        select(
            func.date_trunc("day", SimulationSession.created_at).label("day"),
            func.count(SimulationSession.id).label("count"),
        )
        .where(SimulationSession.created_at >= seven_days_ago)
        .group_by("day")
        .order_by("day")
    )
    sessions_per_day = [
        {"date": row.day.isoformat(), "count": row.count}
        for row in sessions_per_day_result
    ]

    return {
        "total_users": total_users,
        "total_sessions": total_sessions,
        "sessions_per_day_last_7_days": sessions_per_day,
        "generated_at": now.isoformat(),
    }


@router.get("/module/{module_id}")
async def analytics_module(
    module_id: str,
    user: dict[str, Any] = Depends(require_teacher),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Per-module analytics: session count, unique users, average duration."""
    # Verify module exists
    mod_result = await db.execute(
        select(SimulationModule).where(SimulationModule.id == module_id)
    )
    module: SimulationModule | None = mod_result.scalars().first()
    if module is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "MODULE_NOT_FOUND", "message": f"Module '{module_id}' not found."},
        )

    stats = await db.execute(
        select(
            func.count(SimulationSession.id).label("total_sessions"),
            func.count(func.distinct(SimulationSession.user_id)).label("unique_users"),
            func.avg(SimulationSession.duration_ms).label("avg_duration_ms"),
        ).where(SimulationSession.module_id == module_id)
    )
    row = stats.one()

    return {
        "module_id": module_id,
        "module_title": module.title,
        "total_sessions": row.total_sessions or 0,
        "unique_users": row.unique_users or 0,
        "avg_duration_ms": round(row.avg_duration_ms or 0, 2),
    }


@router.get("/user/{user_id}")
async def analytics_user(
    user_id: str,
    current_user: dict[str, Any] = Depends(require_teacher),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Per-student analytics: total sessions, modules attempted, last activity."""
    profile_result = await db.execute(
        select(UserProfile).where(UserProfile.id == user_id)
    )
    profile: UserProfile | None = profile_result.scalars().first()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "USER_NOT_FOUND", "message": f"User '{user_id}' not found."},
        )

    stats = await db.execute(
        select(
            func.count(SimulationSession.id).label("total_sessions"),
            func.count(func.distinct(SimulationSession.module_id)).label("modules_attempted"),
            func.max(SimulationSession.created_at).label("last_activity"),
        ).where(SimulationSession.user_id == user_id)
    )
    row = stats.one()

    return {
        "user_id": user_id,
        "email": profile.email,
        "display_name": profile.display_name,
        "role": profile.role,
        "total_sessions": row.total_sessions or 0,
        "modules_attempted": row.modules_attempted or 0,
        "last_activity": row.last_activity.isoformat() if row.last_activity else None,
    }
