"""
Application configuration using Pydantic Settings.
Reads environment variables from .env file and environment.
"""

from __future__ import annotations

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://conceptra:conceptra_password@localhost:5432/conceptra"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Supabase
    SUPABASE_URL: str = "https://your-project.supabase.co"
    SUPABASE_JWT_SECRET: str = "your-supabase-jwt-secret"
    SUPABASE_ANON_KEY: str = "your-supabase-anon-key"

    # CORS – comma-separated string (avoid pydantic-settings JSON-parsing list fields)
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    # App
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    SECRET_KEY: str = "change-me-in-production"

    # Derived / computed
    IS_PRODUCTION: bool = False
    IS_TESTING: bool = False

    def get_allowed_origins(self) -> list[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    @model_validator(mode="after")
    def set_derived_flags(self) -> "Settings":
        self.IS_PRODUCTION = self.ENVIRONMENT == "production"
        self.IS_TESTING = self.ENVIRONMENT == "testing"
        return self


settings = Settings()
