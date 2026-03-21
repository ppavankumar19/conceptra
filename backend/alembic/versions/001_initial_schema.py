"""Initial schema – all 6 EduViz tables with indexes

Revision ID: 001
Revises:
Create Date: 2024-03-01 00:00:00.000000

"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ------------------------------------------------------------------
    # Enable pgcrypto for gen_random_uuid() if not already enabled
    # ------------------------------------------------------------------
    try:
        op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"')
    except Exception:
        # Managed Postgres providers may disallow CREATE EXTENSION in app migrations.
        # Supabase typically has pgcrypto available already.
        pass

    # ------------------------------------------------------------------
    # user_profiles
    # ------------------------------------------------------------------
    op.create_table(
        "user_profiles",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("supabase_user_id", sa.String(255), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=True),
        sa.Column("role", sa.String(20), server_default="student", nullable=False),
        sa.Column("class_grade", sa.Integer(), nullable=True),
        sa.Column(
            "preferred_language", sa.String(10), server_default="en", nullable=False
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_user_profiles_supabase_user_id", "user_profiles", ["supabase_user_id"], unique=True
    )
    op.create_index("ix_user_profiles_role", "user_profiles", ["role"])

    # ------------------------------------------------------------------
    # simulation_modules
    # ------------------------------------------------------------------
    op.create_table(
        "simulation_modules",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("subject", sa.String(50), nullable=False),
        sa.Column("topic", sa.String(100), nullable=False),
        sa.Column(
            "difficulty", sa.String(20), server_default="beginner", nullable=False
        ),
        sa.Column("grade_min", sa.Integer(), server_default=sa.text("6"), nullable=False),
        sa.Column("grade_max", sa.Integer(), server_default=sa.text("12"), nullable=False),
        sa.Column(
            "is_published",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("user_profiles.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("module_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_simulation_modules_subject", "simulation_modules", ["subject"])
    op.create_index("ix_simulation_modules_topic", "simulation_modules", ["topic"])
    op.create_index(
        "ix_simulation_modules_is_published", "simulation_modules", ["is_published"]
    )
    op.create_index(
        "ix_simulation_modules_difficulty", "simulation_modules", ["difficulty"]
    )

    # ------------------------------------------------------------------
    # module_parameters
    # ------------------------------------------------------------------
    op.create_table(
        "module_parameters",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column(
            "module_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("simulation_modules.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("label", sa.String(200), nullable=False),
        sa.Column("unit", sa.String(50), nullable=True),
        sa.Column("param_type", sa.String(20), server_default="float", nullable=False),
        sa.Column("min_value", sa.Float(), nullable=True),
        sa.Column("max_value", sa.Float(), nullable=True),
        sa.Column("step", sa.Float(), nullable=True),
        sa.Column("default_value", sa.Float(), nullable=True),
        sa.Column(
            "is_required",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("module_id", "name", name="uq_module_parameter_name"),
    )
    op.create_index("ix_module_parameters_module_id", "module_parameters", ["module_id"])

    # ------------------------------------------------------------------
    # simulation_sessions
    # ------------------------------------------------------------------
    op.create_table(
        "simulation_sessions",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "module_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("simulation_modules.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "input_parameters",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
        ),
        sa.Column("result", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column(
            "explanation", postgresql.JSONB(astext_type=sa.Text()), nullable=True
        ),
        sa.Column(
            "graph_data", postgresql.JSONB(astext_type=sa.Text()), nullable=True
        ),
        sa.Column("locale", sa.String(10), server_default="en", nullable=False),
        sa.Column("duration_ms", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_simulation_sessions_user_id", "simulation_sessions", ["user_id"]
    )
    op.create_index(
        "ix_simulation_sessions_module_id", "simulation_sessions", ["module_id"]
    )
    op.create_index(
        "ix_simulation_sessions_created_at", "simulation_sessions", ["created_at"]
    )

    # ------------------------------------------------------------------
    # progress_records
    # ------------------------------------------------------------------
    op.create_table(
        "progress_records",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("user_profiles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "module_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("simulation_modules.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "sessions_count",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
        sa.Column(
            "completion_percentage",
            sa.Float(),
            server_default=sa.text("0.0"),
            nullable=False,
        ),
        sa.Column("last_session_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "extra_data", postgresql.JSONB(astext_type=sa.Text()), nullable=True
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "module_id", name="uq_progress_user_module"),
    )
    op.create_index("ix_progress_records_user_id", "progress_records", ["user_id"])
    op.create_index("ix_progress_records_module_id", "progress_records", ["module_id"])

    # ------------------------------------------------------------------
    # audit_logs
    # ------------------------------------------------------------------
    op.create_table(
        "audit_logs",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=False),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column(
            "actor_id",
            postgresql.UUID(as_uuid=False),
            sa.ForeignKey("user_profiles.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("resource_type", sa.String(100), nullable=True),
        sa.Column("resource_id", sa.String(255), nullable=True),
        sa.Column(
            "log_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=True
        ),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.String(500), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_logs_actor_id", "audit_logs", ["actor_id"])
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])
    op.create_index(
        "ix_audit_logs_action_created_at", "audit_logs", ["action", "created_at"]
    )


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("progress_records")
    op.drop_table("simulation_sessions")
    op.drop_table("module_parameters")
    op.drop_table("simulation_modules")
    op.drop_table("user_profiles")
