"""
Alembic async migration environment.

Uses SQLAlchemy's async engine so that autogenerate and ``alembic upgrade``
both work correctly with asyncpg-based models.
"""

from __future__ import annotations

import asyncio
from logging.config import fileConfig
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# ---------------------------------------------------------------------------
# Import all models so Alembic's autogenerate sees them
# ---------------------------------------------------------------------------
from app.db.models import Base  # noqa: F401 – triggers all model imports
import app.db.models  # noqa: F401

# ---------------------------------------------------------------------------
# Alembic config
# ---------------------------------------------------------------------------
config = context.config

# Interpret the config file for Python logging (if present)
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Override sqlalchemy.url with the application's settings so we have
# one source of truth for the database connection string.
try:
    from app.core.config import settings

    def _normalize_database_url(database_url: str) -> str:
        if database_url.startswith("postgres://"):
            return "postgresql+asyncpg://" + database_url[len("postgres://") :]
        if database_url.startswith("postgresql://"):
            return "postgresql+asyncpg://" + database_url[len("postgresql://") :]
        if database_url.startswith("postgresql+psycopg2://"):
            return "postgresql+asyncpg://" + database_url[len("postgresql+psycopg2://") :]
        return database_url

    def _ensure_pooler_compat(database_url: str) -> str:
        if not database_url.startswith("postgresql+asyncpg://"):
            return database_url
        if ".pooler.supabase.com" not in database_url:
            return database_url

        parts = urlsplit(database_url)
        query = dict(parse_qsl(parts.query, keep_blank_values=True))
        query.setdefault("prepared_statement_cache_size", "0")
        query.setdefault("statement_cache_size", "0")
        updated_query = urlencode(query)
        return urlunsplit((parts.scheme, parts.netloc, parts.path, updated_query, parts.fragment))

    db_url = _ensure_pooler_compat(_normalize_database_url(settings.DATABASE_URL))
    config.set_main_option("sqlalchemy.url", db_url)
except Exception:
    pass  # Fall back to alembic.ini value during standalone `alembic` CLI calls

target_metadata = Base.metadata


# ---------------------------------------------------------------------------
# Offline migrations (generate SQL script without connecting)
# ---------------------------------------------------------------------------


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (emit SQL script)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


# ---------------------------------------------------------------------------
# Online migrations (connect to DB and execute)
# ---------------------------------------------------------------------------


def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Create an async engine and run migrations."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Entry point for online migrations (called by Alembic CLI)."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
