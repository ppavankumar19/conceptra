"""Pydantic v2 schemas for admin-only endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class UserListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    supabase_user_id: str
    email: str
    display_name: str | None = None
    role: str
    class_grade: int | None = None
    is_active: bool
    created_at: datetime


class RoleUpdate(BaseModel):
    role: str = Field(..., pattern="^(student|teacher|admin)$")


class AuditLogEntry(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    actor_id: str | None = None
    action: str
    resource_type: str | None = None
    resource_id: str | None = None
    log_metadata: dict[str, Any] | None = None
    ip_address: str | None = None
    user_agent: str | None = None
    created_at: datetime
