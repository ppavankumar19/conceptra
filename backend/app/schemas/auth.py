"""Pydantic v2 schemas for authentication and user profile endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    supabase_user_id: str
    email: str
    display_name: str | None = None
    role: str
    class_grade: int | None = None
    preferred_language: str = "en"
    is_active: bool = True
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    display_name: str | None = Field(None, max_length=100)
    preferred_language: str | None = Field(None, max_length=10)
    class_grade: int | None = Field(None, ge=6, le=12)
