"""
Role-based access control (RBAC) FastAPI dependencies.

Valid roles (in ascending privilege order): student < teacher < admin
"""

from __future__ import annotations

from typing import Any

from fastapi import Depends, HTTPException, status

from app.core.security import get_current_user

# Role hierarchy
_ROLE_LEVELS: dict[str, int] = {
    "student": 0,
    "teacher": 1,
    "admin": 2,
}


def _role_level(role: str) -> int:
    return _ROLE_LEVELS.get(role.lower(), -1)


def _require_role(minimum_role: str):
    """
    Factory that returns a FastAPI dependency enforcing a minimum role level.
    """

    async def _check(user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
        user_role: str = user.get("role", "student")
        if _role_level(user_role) < _role_level(minimum_role):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "INSUFFICIENT_PERMISSIONS",
                    "message": (
                        f"This action requires the '{minimum_role}' role. "
                        f"Your current role is '{user_role}'."
                    ),
                },
            )
        return user

    return _check


# ---------------------------------------------------------------------------
# Public dependencies
# ---------------------------------------------------------------------------


async def require_student(
    user: dict[str, Any] = Depends(get_current_user),
) -> dict[str, Any]:
    """Allow any authenticated user (student, teacher, or admin)."""
    return user


require_teacher = _require_role("teacher")
require_admin = _require_role("admin")
