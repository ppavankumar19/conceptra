"""
Admin-only endpoints for user management and audit log inspection.

GET  /admin/users                       – paginated user list
PUT  /admin/users/{user_id}/role        – update a user's role
POST /admin/users/{user_id}/deactivate  – deactivate a user account
GET  /admin/audit-logs                  – paginated, filterable audit log
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import require_admin
from app.db.models import AuditLog, UserProfile
from app.db.session import get_db
from app.schemas.admin import AuditLogEntry, RoleUpdate, UserListItem
from app.schemas.common import PaginatedResponse, PaginationMeta, SuccessResponse
from app.services.audit import audit_service

router = APIRouter(prefix="/admin", tags=["admin"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _resolve_actor_id(user: dict[str, Any], db: AsyncSession) -> str | None:
    from sqlalchemy import select as _select

    res = await db.execute(
        _select(UserProfile.id).where(UserProfile.supabase_user_id == user["user_id"])
    )
    return res.scalar_one_or_none()


# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------


@router.get("/users", response_model=PaginatedResponse[UserListItem])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    role: str | None = Query(None),
    is_active: bool | None = Query(None),
    user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[UserListItem]:
    from sqlalchemy import func

    query = select(UserProfile)
    if role is not None:
        query = query.where(UserProfile.role == role)
    if is_active is not None:
        query = query.where(UserProfile.is_active == is_active)

    count_q = select(func.count()).select_from(query.subquery())
    total: int = (await db.execute(count_q)).scalar_one()

    query = query.order_by(UserProfile.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    profiles = (await db.execute(query)).scalars().all()

    data = [UserListItem.model_validate(p) for p in profiles]
    meta = PaginationMeta(page=page, page_size=page_size, total=total)
    return PaginatedResponse[UserListItem](data=data, meta=meta)


@router.put("/users/{user_id}/role", response_model=SuccessResponse[UserListItem])
async def update_user_role(
    user_id: str,
    payload: RoleUpdate,
    request: Request,
    current_user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[UserListItem]:
    actor_id = await _resolve_actor_id(current_user, db)

    result = await db.execute(select(UserProfile).where(UserProfile.id == user_id))
    profile: UserProfile | None = result.scalars().first()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "USER_NOT_FOUND", "message": f"User '{user_id}' not found."},
        )

    old_role = profile.role
    profile.role = payload.role
    await db.flush([profile])

    await audit_service.log(
        db=db,
        actor_id=actor_id,
        action="USER_ROLE_CHANGED",
        resource_type="user",
        resource_id=user_id,
        metadata={"old_role": old_role, "new_role": payload.role},
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    return SuccessResponse(data=UserListItem.model_validate(profile))


@router.post("/users/{user_id}/deactivate", response_model=SuccessResponse[UserListItem])
async def deactivate_user(
    user_id: str,
    request: Request,
    current_user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[UserListItem]:
    actor_id = await _resolve_actor_id(current_user, db)

    result = await db.execute(select(UserProfile).where(UserProfile.id == user_id))
    profile: UserProfile | None = result.scalars().first()
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "USER_NOT_FOUND", "message": f"User '{user_id}' not found."},
        )

    profile.is_active = False
    await db.flush([profile])

    await audit_service.log(
        db=db,
        actor_id=actor_id,
        action="USER_DEACTIVATED",
        resource_type="user",
        resource_id=user_id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    return SuccessResponse(data=UserListItem.model_validate(profile))


# ---------------------------------------------------------------------------
# Audit logs
# ---------------------------------------------------------------------------


@router.get("/audit-logs", response_model=PaginatedResponse[AuditLogEntry])
async def get_audit_logs(
    actor_id: str | None = Query(None),
    action: str | None = Query(None),
    date_from: datetime | None = Query(None),
    date_to: datetime | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[AuditLogEntry]:
    from sqlalchemy import func

    query = select(AuditLog)
    if actor_id is not None:
        query = query.where(AuditLog.actor_id == actor_id)
    if action is not None:
        query = query.where(AuditLog.action == action)
    if date_from is not None:
        query = query.where(AuditLog.created_at >= date_from)
    if date_to is not None:
        query = query.where(AuditLog.created_at <= date_to)

    count_q = select(func.count()).select_from(query.subquery())
    total: int = (await db.execute(count_q)).scalar_one()

    query = query.order_by(AuditLog.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    logs = (await db.execute(query)).scalars().all()

    data = [AuditLogEntry.model_validate(log) for log in logs]
    meta = PaginationMeta(page=page, page_size=page_size, total=total)
    return PaginatedResponse[AuditLogEntry](data=data, meta=meta)
