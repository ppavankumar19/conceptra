"""
Simulation module CRUD endpoints.

GET    /modules                    – list (paginated, filterable, cached)
GET    /modules/{module_id}        – detail (cached)
POST   /modules                    – create (teacher/admin)
PUT    /modules/{module_id}        – update (teacher/admin)
DELETE /modules/{module_id}        – soft-delete (admin)
POST   /modules/{module_id}/publish – toggle publish (admin)
"""

from __future__ import annotations

import hashlib
import json
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.rbac import require_admin, require_student, require_teacher
from app.core.security import get_optional_user
from app.db.models import ModuleParameter, SimulationModule
from app.db.session import get_db
from app.schemas.common import PaginatedResponse, PaginationMeta, SuccessResponse
from app.schemas.modules import (
    CreateModuleRequest,
    ModuleDetail,
    ModuleListItem,
    ModuleParameterSchema,
    UpdateModuleRequest,
)
from app.services.audit import audit_service
from app.services.cache import (
    TTL_MODULE_DETAIL,
    TTL_MODULE_LIST,
    cache_service,
    key_module_detail,
    key_module_list,
    make_hash,
)

router = APIRouter(prefix="/modules", tags=["modules"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _get_module_or_404(module_id: str, db: AsyncSession) -> SimulationModule:
    result = await db.execute(
        select(SimulationModule)
        .options(selectinload(SimulationModule.parameters))
        .where(SimulationModule.id == module_id)
    )
    module: SimulationModule | None = result.scalars().first()
    if module is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "MODULE_NOT_FOUND", "message": f"Module '{module_id}' not found."},
        )
    return module


def _to_module_detail(module: SimulationModule) -> ModuleDetail:
    return ModuleDetail.model_validate(module)


# ---------------------------------------------------------------------------
# List modules
# ---------------------------------------------------------------------------


@router.get("", response_model=PaginatedResponse[ModuleListItem])
async def list_modules(
    subject: str | None = Query(None),
    difficulty: str | None = Query(None),
    grade: int | None = Query(None, ge=6, le=12),
    is_published: bool | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict[str, Any] | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[ModuleListItem]:
    # Unauthenticated users and students can only see published modules
    role = user.get("role", "student") if user else "student"
    if role == "student":
        is_published = True

    filter_payload = {
        "subject": subject,
        "difficulty": difficulty,
        "grade": grade,
        "is_published": is_published,
        "page": page,
        "page_size": page_size,
    }
    filter_hash = make_hash(filter_payload)
    cache_key = key_module_list(filter_hash)

    cached = await cache_service.get(cache_key)
    if cached is not None:
        return PaginatedResponse[ModuleListItem](**cached)

    query = select(SimulationModule)
    if subject is not None:
        query = query.where(SimulationModule.subject == subject)
    if difficulty is not None:
        query = query.where(SimulationModule.difficulty == difficulty)
    if grade is not None:
        query = query.where(
            SimulationModule.grade_min <= grade,
            SimulationModule.grade_max >= grade,
        )
    if is_published is not None:
        query = query.where(SimulationModule.is_published == is_published)

    count_q = select(func.count()).select_from(query.subquery())
    total: int = (await db.execute(count_q)).scalar_one()

    query = query.order_by(SimulationModule.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    modules = (await db.execute(query)).scalars().all()

    data = [ModuleListItem.model_validate(m) for m in modules]
    meta = PaginationMeta(page=page, page_size=page_size, total=total)

    response = PaginatedResponse[ModuleListItem](data=data, meta=meta)
    await cache_service.set(cache_key, response.model_dump(mode="json"), ttl=TTL_MODULE_LIST)
    return response


# ---------------------------------------------------------------------------
# Get single module
# ---------------------------------------------------------------------------


@router.get("/{module_id}", response_model=SuccessResponse[ModuleDetail])
async def get_module(
    module_id: str,
    user: dict[str, Any] | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ModuleDetail]:
    cache_key = key_module_detail(module_id)
    cached = await cache_service.get(cache_key)
    if cached is not None:
        return SuccessResponse[ModuleDetail](data=ModuleDetail(**cached))

    module = await _get_module_or_404(module_id, db)

    # Unauthenticated users and students can only see published modules
    role = user.get("role") if user else "student"
    if role == "student" and not module.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "MODULE_NOT_FOUND", "message": f"Module '{module_id}' not found."},
        )

    detail = _to_module_detail(module)
    await cache_service.set(
        cache_key, detail.model_dump(mode="json"), ttl=TTL_MODULE_DETAIL
    )
    return SuccessResponse(data=detail)


# ---------------------------------------------------------------------------
# Create module
# ---------------------------------------------------------------------------


@router.post("", response_model=SuccessResponse[ModuleDetail], status_code=status.HTTP_201_CREATED)
async def create_module(
    payload: CreateModuleRequest,
    request: Request,
    user: dict[str, Any] = Depends(require_teacher),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ModuleDetail]:
    # Resolve creator's UserProfile id
    from sqlalchemy import select as _select
    from app.db.models import UserProfile

    creator_result = await db.execute(
        _select(UserProfile.id).where(
            UserProfile.supabase_user_id == user["user_id"]
        )
    )
    creator_id: str | None = creator_result.scalar_one_or_none()

    module = SimulationModule(
        title=payload.title,
        description=payload.description,
        subject=payload.subject,
        topic=payload.topic,
        difficulty=payload.difficulty,
        grade_min=payload.grade_min,
        grade_max=payload.grade_max,
        is_published=payload.is_published,
        created_by=creator_id,
        module_metadata=payload.module_metadata,
    )
    db.add(module)
    await db.flush([module])

    for param_schema in payload.parameters:
        param = ModuleParameter(
            module_id=module.id,
            name=param_schema.name,
            label=param_schema.label,
            unit=param_schema.unit,
            param_type=param_schema.param_type,
            min_value=param_schema.min_value,
            max_value=param_schema.max_value,
            step=param_schema.step,
            default_value=param_schema.default_value,
            is_required=param_schema.is_required,
        )
        db.add(param)

    await db.flush()

    # Reload with relationships
    module = await _get_module_or_404(module.id, db)

    await audit_service.log(
        db=db,
        actor_id=creator_id,
        action="MODULE_CREATED",
        resource_type="module",
        resource_id=module.id,
        log_metadata={"title": module.title},
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    # Invalidate module list cache
    await cache_service.delete_pattern("conceptra:modules:list:*")

    return SuccessResponse(data=_to_module_detail(module))


# ---------------------------------------------------------------------------
# Update module
# ---------------------------------------------------------------------------


@router.put("/{module_id}", response_model=SuccessResponse[ModuleDetail])
async def update_module(
    module_id: str,
    payload: UpdateModuleRequest,
    request: Request,
    user: dict[str, Any] = Depends(require_teacher),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ModuleDetail]:
    from app.db.models import UserProfile

    actor_result = await db.execute(
        select(UserProfile.id).where(UserProfile.supabase_user_id == user["user_id"])
    )
    actor_id: str | None = actor_result.scalar_one_or_none()

    module = await _get_module_or_404(module_id, db)

    update_data = payload.model_dump(exclude_none=True, exclude={"parameters"})
    for field, value in update_data.items():
        setattr(module, field, value)

    if payload.parameters is not None:
        # Replace all parameters
        for existing_param in list(module.parameters):
            db.delete(existing_param)
        await db.flush()

        for param_schema in payload.parameters:
            param = ModuleParameter(
                module_id=module.id,
                name=param_schema.name,
                label=param_schema.label,
                unit=param_schema.unit,
                param_type=param_schema.param_type,
                min_value=param_schema.min_value,
                max_value=param_schema.max_value,
                step=param_schema.step,
                default_value=param_schema.default_value,
                is_required=param_schema.is_required,
            )
            db.add(param)

    await db.flush()

    module = await _get_module_or_404(module_id, db)

    await audit_service.log(
        db=db,
        actor_id=actor_id,
        action="MODULE_UPDATED",
        resource_type="module",
        resource_id=module_id,
        log_metadata=update_data,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    # Invalidate caches
    await cache_service.delete(key_module_detail(module_id))
    await cache_service.delete_pattern("conceptra:modules:list:*")

    return SuccessResponse(data=_to_module_detail(module))


# ---------------------------------------------------------------------------
# Delete module (soft delete – admin only)
# ---------------------------------------------------------------------------


@router.delete("/{module_id}", status_code=status.HTTP_200_OK)
async def delete_module(
    module_id: str,
    request: Request,
    user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> None:
    from app.db.models import UserProfile

    actor_result = await db.execute(
        select(UserProfile.id).where(UserProfile.supabase_user_id == user["user_id"])
    )
    actor_id: str | None = actor_result.scalar_one_or_none()

    module = await _get_module_or_404(module_id, db)

    # Soft-delete: unpublish and mark as deleted via metadata
    module.is_published = False
    existing_meta = module.module_metadata or {}
    existing_meta["deleted"] = True
    module.module_metadata = existing_meta
    await db.flush([module])

    await audit_service.log(
        db=db,
        actor_id=actor_id,
        action="MODULE_DELETED",
        resource_type="module",
        resource_id=module_id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    await cache_service.delete(key_module_detail(module_id))
    await cache_service.delete_pattern("conceptra:modules:list:*")


# ---------------------------------------------------------------------------
# Publish / unpublish (admin only)
# ---------------------------------------------------------------------------


@router.post("/{module_id}/publish", response_model=SuccessResponse[ModuleDetail])
async def publish_module(
    module_id: str,
    request: Request,
    user: dict[str, Any] = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[ModuleDetail]:
    from app.db.models import UserProfile

    actor_result = await db.execute(
        select(UserProfile.id).where(UserProfile.supabase_user_id == user["user_id"])
    )
    actor_id: str | None = actor_result.scalar_one_or_none()

    module = await _get_module_or_404(module_id, db)
    module.is_published = not module.is_published
    await db.flush([module])

    action = "MODULE_PUBLISHED" if module.is_published else "MODULE_UNPUBLISHED"
    await audit_service.log(
        db=db,
        actor_id=actor_id,
        action=action,
        resource_type="module",
        resource_id=module_id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    await cache_service.delete(key_module_detail(module_id))
    await cache_service.delete_pattern("conceptra:modules:list:*")

    module = await _get_module_or_404(module_id, db)
    return SuccessResponse(data=_to_module_detail(module))
