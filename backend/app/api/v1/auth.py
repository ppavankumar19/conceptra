"""
Authentication routes.

GET /auth/me  – fetch (or auto-create) the current user's profile
PUT /auth/me  – update display_name, preferred_language, class_grade
"""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.models import UserProfile
from app.db.session import get_db
from app.schemas.auth import UserProfileResponse, UserProfileUpdate
from app.schemas.common import SuccessResponse

router = APIRouter(prefix="/auth", tags=["auth"])


async def _get_or_create_profile(
    user: dict[str, Any], db: AsyncSession
) -> UserProfile:
    """
    Look up the UserProfile by supabase_user_id.
    If not found, create one from the JWT claims and flush it.
    """
    supabase_uid: str = user["user_id"]

    result = await db.execute(
        select(UserProfile).where(UserProfile.supabase_user_id == supabase_uid)
    )
    profile: UserProfile | None = result.scalars().first()

    if profile is None:
        # Extract email from JWT payload (Supabase stores it here)
        email: str = (
            user.get("email")
            or (user.get("user_metadata") or {}).get("email")
            or f"{supabase_uid}@unknown.local"
        )
        role: str = user.get("role", "student")
        # Normalise role to our allowed values
        if role not in ("student", "teacher", "admin"):
            role = "student"

        profile = UserProfile(
            supabase_user_id=supabase_uid,
            email=email,
            display_name=(user.get("user_metadata") or {}).get("full_name"),
            role=role,
        )
        db.add(profile)
        await db.flush([profile])

    return profile


@router.get("/me", response_model=SuccessResponse[UserProfileResponse])
async def get_me(
    user: dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[UserProfileResponse]:
    """Return the authenticated user's profile, creating it on first login."""
    profile = await _get_or_create_profile(user, db)
    return SuccessResponse(data=UserProfileResponse.model_validate(profile))


@router.put("/me", response_model=SuccessResponse[UserProfileResponse])
async def update_me(
    payload: UserProfileUpdate,
    user: dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SuccessResponse[UserProfileResponse]:
    """Update mutable fields on the current user's profile."""
    profile = await _get_or_create_profile(user, db)

    update_data = payload.model_dump(exclude_none=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    await db.flush([profile])
    return SuccessResponse(data=UserProfileResponse.model_validate(profile))
