"""
Audit logging service.

Writes immutable audit records to the ``audit_logs`` table for every
significant action (role changes, module mutations, user deactivation, etc.).
"""

from __future__ import annotations

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging_config import get_logger
from app.db.models import AuditLog

logger = get_logger(__name__)


class AuditService:
    """Async service for recording audit events to the database."""

    async def log(
        self,
        db: AsyncSession,
        actor_id: str | None,
        action: str,
        resource_type: str | None = None,
        resource_id: str | None = None,
        log_metadata: dict[str, Any] | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> AuditLog:
        """
        Persist a single audit event.

        Args:
            db:            Active async database session.
            actor_id:      UserProfile.id of the user performing the action.
            action:        Action name, e.g. ``MODULE_CREATED``, ``USER_ROLE_CHANGED``.
            resource_type: Entity type affected, e.g. ``module``, ``user``.
            resource_id:   Primary key of the affected entity.
            log_metadata:  Arbitrary JSON-serialisable context dict.
            ip_address:    Client IP address (max 45 chars for IPv6).
            user_agent:    HTTP User-Agent header value.

        Returns:
            The persisted AuditLog ORM instance.
        """
        entry = AuditLog(
            actor_id=actor_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            log_metadata=log_metadata,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.add(entry)
        # Flush so the entry gets a server-generated ID but leave the commit
        # to the caller (or the get_db dependency).
        await db.flush([entry])

        logger.info(
            "audit_event",
            actor_id=actor_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
        )
        return entry


audit_service = AuditService()
