"""
Standard Pydantic v2 response envelope schemas used across the entire API.
"""

from __future__ import annotations

import math
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, Field, model_validator

T = TypeVar("T")


# ---------------------------------------------------------------------------
# Error shapes
# ---------------------------------------------------------------------------


class FieldError(BaseModel):
    field: str
    message: str


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: list[FieldError] | None = None


class ErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail


# ---------------------------------------------------------------------------
# Success shapes
# ---------------------------------------------------------------------------


class SuccessResponse(BaseModel, Generic[T]):
    success: bool = True
    data: T


# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------


class PaginationMeta(BaseModel):
    page: int = Field(ge=1)
    page_size: int = Field(ge=1, le=200)
    total: int = Field(ge=0)
    total_pages: int = Field(ge=0)

    @model_validator(mode="before")
    @classmethod
    def compute_total_pages(cls, values: dict[str, Any]) -> dict[str, Any]:
        total = values.get("total", 0)
        page_size = values.get("page_size", 1)
        if page_size and "total_pages" not in values:
            values["total_pages"] = math.ceil(total / page_size) if page_size else 0
        return values


class PaginatedResponse(BaseModel, Generic[T]):
    success: bool = True
    data: list[T]
    meta: PaginationMeta
