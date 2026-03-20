"""Pydantic v2 schemas for simulation modules."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ModuleParameterSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str | None = None
    name: str
    label: str
    unit: str | None = None
    param_type: str = "float"
    min_value: float | None = None
    max_value: float | None = None
    step: float | None = None
    default_value: float | None = None
    is_required: bool = True


class ModuleListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    subject: str
    topic: str
    difficulty: str
    grade_min: int
    grade_max: int
    is_published: bool
    created_at: datetime


class ModuleDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    description: str | None = None
    subject: str
    topic: str
    difficulty: str
    grade_min: int
    grade_max: int
    is_published: bool
    created_by: str | None = None
    module_metadata: dict[str, Any] | None = None
    parameters: list[ModuleParameterSchema] = []
    created_at: datetime
    updated_at: datetime


class CreateModuleRequest(BaseModel):
    title: str = Field(..., max_length=200)
    description: str | None = None
    subject: str = Field(..., max_length=50)
    topic: str = Field(..., max_length=100)
    difficulty: str = Field("beginner", pattern="^(beginner|intermediate|advanced)$")
    grade_min: int = Field(6, ge=6, le=12)
    grade_max: int = Field(12, ge=6, le=12)
    is_published: bool = False
    module_metadata: dict[str, Any] | None = None
    parameters: list[ModuleParameterSchema] = []


class UpdateModuleRequest(BaseModel):
    title: str | None = Field(None, max_length=200)
    description: str | None = None
    subject: str | None = Field(None, max_length=50)
    topic: str | None = Field(None, max_length=100)
    difficulty: str | None = Field(None, pattern="^(beginner|intermediate|advanced)$")
    grade_min: int | None = Field(None, ge=6, le=12)
    grade_max: int | None = Field(None, ge=6, le=12)
    is_published: bool | None = None
    module_metadata: dict[str, Any] | None = None
    parameters: list[ModuleParameterSchema] | None = None
