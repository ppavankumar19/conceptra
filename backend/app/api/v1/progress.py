"""
Student progress tracking endpoints.

GET /progress              – all progress records for current user
GET /progress/{module_id}  – progress for a specific module
PUT /progress/{module_id}  – upsert progress record
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_student
from app.db.models import ProgressRecord, SimulationModule, UserProfile
from app.db.session import get_db
from app.schemas.common import SuccessResponse
from app.schemas.progress import ProgressRecordSchema, ProgressUpdate

router = APIRouter(prefix="/progress", tags=["progress"])


async def _resolve_profile(user: dict[str, Any], db: AsyncSession) -> UserProfile:
    result = await db.execute(
        select(UserProfile).where(UserProfile.supabase_user_id == user["user_id"])
    )
    profile: UserProfile | None = result.scalars().first()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "PROFILE_NOT_FOUND", "message": "User profile not found."},
        )
    return profile


@router.get("", response_model=SuccessResponse[list[ProgressRecordSchema]])
async def get_all_progress(
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[list[ProgressRecordSchema]]:
    """Return all progress records for the authenticated user."""
    profile = await _resolve_profile(user, db)

    result = await db.execute(
        select(ProgressRecord)
        .where(ProgressRecord.user_id == profile.id)
        .order_by(ProgressRecord.updated_at.desc())
    )
    records = result.scalars().all()
    data = [ProgressRecordSchema.model_validate(r) for r in records]
    return SuccessResponse(data=data)


@router.get("/{module_id}", response_model=SuccessResponse[ProgressRecordSchema])
async def get_module_progress(
    module_id: str,
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ProgressRecordSchema]:
    """Return the progress record for the authenticated user on a specific module."""
    profile = await _resolve_profile(user, db)

    result = await db.execute(
        select(ProgressRecord).where(
            ProgressRecord.user_id == profile.id,
            ProgressRecord.module_id == module_id,
        )
    )
    record: ProgressRecord | None = result.scalars().first()
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "PROGRESS_NOT_FOUND",
                "message": f"No progress record found for module '{module_id}'.",
            },
        )

    return SuccessResponse(data=ProgressRecordSchema.model_validate(record))


@router.put("/{module_id}", response_model=SuccessResponse[ProgressRecordSchema])
async def upsert_module_progress(
    module_id: str,
    payload: ProgressUpdate,
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ProgressRecordSchema]:
    """Upsert progress for the authenticated user on a specific module."""
    profile = await _resolve_profile(user, db)

    # Ensure module exists
    mod_result = await db.execute(
        select(SimulationModule.id).where(SimulationModule.id == module_id)
    )
    if mod_result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "MODULE_NOT_FOUND", "message": f"Module '{module_id}' not found."},
        )

    result = await db.execute(
        select(ProgressRecord).where(
            ProgressRecord.user_id == profile.id,
            ProgressRecord.module_id == module_id,
        )
    )
    record: ProgressRecord | None = result.scalars().first()

    now = datetime.now(timezone.utc)

    if record is None:
        record = ProgressRecord(
            user_id=profile.id,
            module_id=module_id,
            sessions_count=payload.sessions_count or 0,
            completion_percentage=payload.completion_percentage,
            last_session_at=now,
            extra_data=payload.extra_data,
        )
        db.add(record)
    else:
        record.completion_percentage = payload.completion_percentage
        if payload.sessions_count is not None:
            record.sessions_count = payload.sessions_count
        record.last_session_at = now
        if payload.extra_data is not None:
            record.extra_data = payload.extra_data

    await db.flush([record])
    return SuccessResponse(data=ProgressRecordSchema.model_validate(record))
