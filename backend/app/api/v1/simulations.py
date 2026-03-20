"""
Simulation execution and history endpoints.

POST /simulate              – run a simulation, save session, update progress
GET  /simulate/history      – paginated history for current user
GET  /simulate/{session_id} – single session (owner only)
"""

from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.rbac import require_student
from app.db.models import ModuleParameter, ProgressRecord, SimulationModule, SimulationSession, UserProfile
from app.db.session import get_db
from app.schemas.common import PaginatedResponse, PaginationMeta, SuccessResponse
from app.schemas.simulations import SimulateRequest, SimulateResponse, SimulationSessionHistory
from app.services.cache import (
    TTL_SIM_RESULT,
    cache_service,
    key_sim_result,
    make_hash,
)
from app.services.computation import computation_router

router = APIRouter(prefix="/simulate", tags=["simulations"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _resolve_profile(user: dict[str, Any], db: AsyncSession) -> UserProfile:
    result = await db.execute(
        select(UserProfile).where(UserProfile.supabase_user_id == user["user_id"])
    )
    profile: UserProfile | None = result.scalars().first()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "PROFILE_NOT_FOUND", "message": "User profile not found. Call GET /auth/me first."},
        )
    return profile


async def _load_module(module_id: str, db: AsyncSession) -> SimulationModule:
    result = await db.execute(
        select(SimulationModule)
        .options(selectinload(SimulationModule.parameters))
        .where(SimulationModule.id == module_id)
    )
    module: SimulationModule | None = result.scalars().first()
    if module is None or not module.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "MODULE_NOT_FOUND", "message": f"Module '{module_id}' not found or not published."},
        )
    return module


def _validate_parameters(
    parameters: dict[str, float],
    module_params: list[ModuleParameter],
) -> None:
    """
    Validate that all required parameters are present and within their
    defined min/max bounds.
    """
    param_map = {p.name: p for p in module_params}

    # Check required parameters are present
    for param in module_params:
        if param.is_required and param.name not in parameters:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "MISSING_PARAMETER",
                    "message": f"Required parameter '{param.name}' is missing.",
                },
            )

    # Validate bounds
    for name, value in parameters.items():
        if name not in param_map:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "UNKNOWN_PARAMETER",
                    "message": f"Unknown parameter '{name}' for this module.",
                },
            )
        param_def = param_map[name]
        if param_def.min_value is not None and value < param_def.min_value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "PARAMETER_OUT_OF_RANGE",
                    "message": (
                        f"Parameter '{name}' value {value} is below minimum {param_def.min_value}."
                    ),
                },
            )
        if param_def.max_value is not None and value > param_def.max_value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "PARAMETER_OUT_OF_RANGE",
                    "message": (
                        f"Parameter '{name}' value {value} exceeds maximum {param_def.max_value}."
                    ),
                },
            )


# ---------------------------------------------------------------------------
# POST /simulate
# ---------------------------------------------------------------------------


@router.post("", response_model=SuccessResponse[SimulateResponse])
async def run_simulation(
    payload: SimulateRequest,
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[SimulateResponse]:
    profile = await _resolve_profile(user, db)
    module = await _load_module(payload.module_id, db)

    _validate_parameters(payload.parameters, module.parameters)

    # Check cache
    params_hash = make_hash(payload.parameters)
    cache_key = key_sim_result(payload.module_id, params_hash)
    cached_result = await cache_service.get(cache_key)

    t_start = time.perf_counter()

    # Run computation — catch any engine errors and return a clean 500
    try:
        if cached_result is None:
            computation = computation_router.route(module.topic, payload.parameters)
            await cache_service.set(cache_key, computation, ttl=TTL_SIM_RESULT)
        else:
            computation = cached_result
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"code": "COMPUTATION_ERROR", "message": str(exc)},
        ) from exc

    duration_ms = int((time.perf_counter() - t_start) * 1000)

    # Persist session (best-effort — never block the response on DB write failures)
    try:
        session = SimulationSession(
            user_id=profile.id,
            module_id=module.id,
            input_parameters=payload.parameters,
            result=computation["result"],
            explanation=computation.get("explanation"),
            graph_data=computation.get("graph_data"),
            locale=payload.locale,
            duration_ms=duration_ms,
        )
        db.add(session)
        await db.flush([session])

        # Upsert progress record
        now = datetime.now(timezone.utc)

        pr_result = await db.execute(
            select(ProgressRecord).where(
                ProgressRecord.user_id == profile.id,
                ProgressRecord.module_id == module.id,
            )
        )
        progress: ProgressRecord | None = pr_result.scalars().first()

        if progress is None:
            progress = ProgressRecord(
                user_id=profile.id,
                module_id=module.id,
                sessions_count=1,
                completion_percentage=0.0,
                last_session_at=now,
            )
            db.add(progress)
        else:
            progress.sessions_count += 1
            progress.last_session_at = now

        await db.flush([progress])
        session_id = session.id
    except Exception:
        # DB write failure: return result without persisting.
        # Do NOT call db.rollback() here — the get_db dependency handles
        # cleanup, and calling await inside this except block triggers the
        # greenlet incompatibility with asyncpg when run under pure ASGI middleware.
        session_id = "offline-" + module.id[:8]

    result_dict = computation["result"]
    response_data = SimulateResponse(
        session_id=session_id,
        module_id=module.id,
        topic=module.topic,
        input_parameters=payload.parameters,
        result=result_dict,
        result_value=float(result_dict.get("value", 0.0)),
        result_unit=str(result_dict.get("unit", "")),
        result_label=str(result_dict.get("label", "Result")),
        explanation=computation["explanation"],
        graph_data=computation.get("graph_data"),
    )
    return SuccessResponse(data=response_data)


# ---------------------------------------------------------------------------
# GET /simulate/history
# ---------------------------------------------------------------------------


@router.get("/history", response_model=PaginatedResponse[SimulationSessionHistory])
async def get_simulation_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[SimulationSessionHistory]:
    profile = await _resolve_profile(user, db)

    from sqlalchemy import func

    count_q = select(func.count(SimulationSession.id)).where(
        SimulationSession.user_id == profile.id
    )
    total: int = (await db.execute(count_q)).scalar_one()

    sessions_q = (
        select(SimulationSession)
        .where(SimulationSession.user_id == profile.id)
        .order_by(SimulationSession.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    sessions = (await db.execute(sessions_q)).scalars().all()

    data = [SimulationSessionHistory.model_validate(s) for s in sessions]
    meta = PaginationMeta(page=page, page_size=page_size, total=total)
    return PaginatedResponse[SimulationSessionHistory](data=data, meta=meta)


# ---------------------------------------------------------------------------
# GET /simulate/{session_id}
# ---------------------------------------------------------------------------


@router.get("/{session_id}", response_model=SuccessResponse[SimulationSessionHistory])
async def get_simulation_session(
    session_id: str,
    user: dict[str, Any] = Depends(require_student),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[SimulationSessionHistory]:
    profile = await _resolve_profile(user, db)

    result = await db.execute(
        select(SimulationSession).where(SimulationSession.id == session_id)
    )
    session: SimulationSession | None = result.scalars().first()

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "SESSION_NOT_FOUND", "message": f"Session '{session_id}' not found."},
        )

    if session.user_id != profile.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "FORBIDDEN",
                "message": "You do not have access to this session.",
            },
        )

    return SuccessResponse(data=SimulationSessionHistory.model_validate(session))
