"""Pydantic v2 schemas for student progress tracking."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ProgressRecordSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    module_id: str
    sessions_count: int
    completion_percentage: float
    last_session_at: datetime | None = None
    extra_data: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime


class ProgressUpdate(BaseModel):
    completion_percentage: float = Field(..., ge=0.0, le=100.0)
    sessions_count: int | None = Field(None, ge=0)
    extra_data: dict[str, Any] | None = None
