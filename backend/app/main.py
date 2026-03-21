"""
Conceptra FastAPI application entry point.

Responsibilities:
- Configure structured logging
- Build the FastAPI app with all middleware
- Register all API routers under /api/v1
- Global exception handler
- Startup hook: run Alembic migrations + seed initial data
- /metrics endpoint (Prometheus)
"""

from __future__ import annotations

import traceback
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.logging_config import get_logger, setup_logging
from app.core.middleware import CorrelationIDMiddleware, RequestLoggingMiddleware

# Configure logging immediately on import
setup_logging(
    log_level=settings.LOG_LEVEL,
    json_logs=settings.IS_PRODUCTION,
)

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Startup / shutdown lifecycle
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Run startup tasks before the app serves traffic."""
    logger.info("conceptra_startup", environment=settings.ENVIRONMENT)

    # Run Alembic migrations
    try:
        _run_migrations()
    except Exception as exc:
        logger.error("migration_failed", error=str(exc))
        # Do not abort startup in dev – DB may be a fresh blank instance
        if settings.IS_PRODUCTION:
            raise

    # Seed initial data
    try:
        await _seed_initial_data()
    except Exception as exc:
        logger.warning("seed_failed", error=str(exc))

    # Invalidate module list cache so stale cached data doesn't hide newly published modules
    try:
        from app.services.cache import cache_service
        await cache_service.delete_pattern("conceptra:modules:list:*")
        logger.info("module_list_cache_cleared")
    except Exception as exc:
        logger.warning("cache_clear_failed", error=str(exc))

    yield

    # Shutdown
    from app.services.cache import cache_service

    await cache_service.close()
    logger.info("conceptra_shutdown")


def _run_migrations() -> None:
    """Run Alembic migrations synchronously at startup."""
    from alembic import command
    from alembic.config import Config

    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
    logger.info("migrations_applied")


async def _seed_initial_data() -> None:
    """Seed all simulation modules if they don't already exist (checked by title)."""
    from sqlalchemy import select
    from sqlalchemy.orm import selectinload

    from app.db.models import ModuleParameter, SimulationModule
    from app.db.session import AsyncSessionLocal

    MODULES_SEED = [
        # ── Physics ──────────────────────────────────────────────────────
        {
            "title": "Speed",
            "description": "Explore the relationship between distance, time, and speed. Suitable for Classes 6–8 (Physics / Motion chapter).",
            "subject": "physics",
            "topic": "speed",
            "difficulty": "beginner",
            "grade_min": 6,
            "grade_max": 8,
            "module_metadata": {"icon": "speedometer", "color": "#4CAF50"},
            "params": [
                {"name": "distance", "label": "Distance", "unit": "m", "min_value": 0.1, "max_value": 10000.0, "default_value": 100.0},
                {"name": "time", "label": "Time", "unit": "s", "min_value": 0.1, "max_value": 3600.0, "default_value": 10.0},
            ],
        },
        {
            "title": "Acceleration",
            "description": "Understand how velocity changes over time and calculate acceleration.",
            "subject": "physics",
            "topic": "acceleration",
            "difficulty": "intermediate",
            "grade_min": 9,
            "grade_max": 10,
            "module_metadata": {"icon": "trending_up", "color": "#2196F3"},
            "params": [
                {"name": "initial_velocity", "label": "Initial Velocity", "unit": "m/s", "min_value": 0.0, "max_value": 500.0, "default_value": 0.0},
                {"name": "final_velocity", "label": "Final Velocity", "unit": "m/s", "min_value": 0.0, "max_value": 500.0, "default_value": 20.0},
                {"name": "time", "label": "Time", "unit": "s", "min_value": 0.1, "max_value": 3600.0, "default_value": 5.0},
            ],
        },
        {
            "title": "Newton's Second Law (Force)",
            "description": "Explore Newton's Second Law: Force equals mass times acceleration.",
            "subject": "physics",
            "topic": "force",
            "difficulty": "intermediate",
            "grade_min": 9,
            "grade_max": 10,
            "module_metadata": {"icon": "bolt", "color": "#FF5722"},
            "params": [
                {"name": "mass", "label": "Mass", "unit": "kg", "min_value": 0.001, "max_value": 10000.0, "default_value": 10.0},
                {"name": "acceleration", "label": "Acceleration", "unit": "m/s²", "min_value": -100.0, "max_value": 100.0, "default_value": 9.8},
            ],
        },
        {
            "title": "Work and Energy",
            "description": "Calculate work done by a force over a displacement at an angle.",
            "subject": "physics",
            "topic": "work_energy",
            "difficulty": "intermediate",
            "grade_min": 9,
            "grade_max": 10,
            "module_metadata": {"icon": "fitness_center", "color": "#9C27B0"},
            "params": [
                {"name": "force", "label": "Force", "unit": "N", "min_value": 0.0, "max_value": 10000.0, "default_value": 50.0},
                {"name": "displacement", "label": "Displacement", "unit": "m", "min_value": 0.0, "max_value": 1000.0, "default_value": 10.0},
                {"name": "angle_degrees", "label": "Angle", "unit": "°", "min_value": 0.0, "max_value": 90.0, "default_value": 0.0},
            ],
        },
        {
            "title": "Pressure",
            "description": "Understand how pressure depends on force and the area it acts upon.",
            "subject": "physics",
            "topic": "pressure",
            "difficulty": "beginner",
            "grade_min": 8,
            "grade_max": 9,
            "module_metadata": {"icon": "compress", "color": "#00BCD4"},
            "params": [
                {"name": "force", "label": "Force", "unit": "N", "min_value": 0.01, "max_value": 100000.0, "default_value": 100.0},
                {"name": "area", "label": "Area", "unit": "m²", "min_value": 0.0001, "max_value": 1000.0, "default_value": 0.5},
            ],
        },
        {
            "title": "Density",
            "description": "Calculate the density of substances given their mass and volume.",
            "subject": "physics",
            "topic": "density",
            "difficulty": "beginner",
            "grade_min": 8,
            "grade_max": 9,
            "module_metadata": {"icon": "water", "color": "#607D8B"},
            "params": [
                {"name": "mass", "label": "Mass", "unit": "kg", "min_value": 0.001, "max_value": 100000.0, "default_value": 1.0},
                {"name": "volume", "label": "Volume", "unit": "m³", "min_value": 0.0001, "max_value": 1000.0, "default_value": 0.001},
            ],
        },
        {
            "title": "Ohm's Law",
            "description": "Explore the relationship between voltage, current, and resistance in a circuit.",
            "subject": "physics",
            "topic": "ohms_law",
            "difficulty": "intermediate",
            "grade_min": 10,
            "grade_max": 10,
            "module_metadata": {"icon": "electric_bolt", "color": "#FFC107"},
            "params": [
                {"name": "voltage", "label": "Voltage", "unit": "V", "min_value": 0.001, "max_value": 1000.0, "default_value": 12.0},
                {"name": "resistance", "label": "Resistance", "unit": "ohm", "min_value": 0.001, "max_value": 10000.0, "default_value": 6.0},
            ],
        },
        {
            "title": "Simple Pendulum",
            "description": "Discover how the length of a pendulum affects its period of oscillation.",
            "subject": "physics",
            "topic": "pendulum",
            "difficulty": "intermediate",
            "grade_min": 11,
            "grade_max": 12,
            "module_metadata": {"icon": "pending", "color": "#795548"},
            "params": [
                {"name": "length", "label": "Length", "unit": "m", "min_value": 0.01, "max_value": 100.0, "default_value": 1.0},
                {"name": "gravity", "label": "Gravity", "unit": "m/s²", "min_value": 1.0, "max_value": 30.0, "default_value": 9.8},
            ],
        },
        {
            "title": "Projectile Motion",
            "description": "Analyse the trajectory, range, and height of a projectile launched at an angle.",
            "subject": "physics",
            "topic": "projectile",
            "difficulty": "advanced",
            "grade_min": 11,
            "grade_max": 12,
            "module_metadata": {"icon": "sports_baseball", "color": "#F44336"},
            "params": [
                {"name": "initial_velocity", "label": "Initial Velocity", "unit": "m/s", "min_value": 1.0, "max_value": 500.0, "default_value": 30.0},
                {"name": "angle_degrees", "label": "Launch Angle", "unit": "°", "min_value": 1.0, "max_value": 89.0, "default_value": 45.0},
                {"name": "gravity", "label": "Gravity", "unit": "m/s²", "min_value": 1.0, "max_value": 30.0, "default_value": 9.8},
            ],
        },
        {
            "title": "Gravitational Force",
            "description": "Calculate the gravitational force between two masses using Newton's Law of Gravitation.",
            "subject": "physics",
            "topic": "gravitational_force",
            "difficulty": "advanced",
            "grade_min": 9,
            "grade_max": 11,
            "module_metadata": {"icon": "public", "color": "#3F51B5"},
            "params": [
                {"name": "mass1", "label": "Mass 1", "unit": "kg", "min_value": 1.0, "max_value": 1e30, "default_value": 5.97e24},
                {"name": "mass2", "label": "Mass 2", "unit": "kg", "min_value": 1.0, "max_value": 1e30, "default_value": 7.35e22},
                {"name": "distance", "label": "Distance", "unit": "m", "min_value": 1.0, "max_value": 1e12, "default_value": 3.84e8},
            ],
        },
        # ── Mathematics ──────────────────────────────────────────────────
        {
            "title": "Linear Equation",
            "description": "Visualise and explore linear equations of the form y = mx + c.",
            "subject": "mathematics",
            "topic": "linear_equation",
            "difficulty": "beginner",
            "grade_min": 8,
            "grade_max": 10,
            "module_metadata": {"icon": "show_chart", "color": "#009688"},
            "params": [
                {"name": "slope", "label": "Slope (m)", "unit": "", "min_value": -50.0, "max_value": 50.0, "default_value": 2.0},
                {"name": "intercept", "label": "Intercept (c)", "unit": "", "min_value": -50.0, "max_value": 50.0, "default_value": 1.0},
            ],
        },
        {
            "title": "Quadratic Equation",
            "description": "Explore quadratic equations y = ax² + bx + c, their roots, and vertex.",
            "subject": "mathematics",
            "topic": "quadratic",
            "difficulty": "intermediate",
            "grade_min": 10,
            "grade_max": 11,
            "module_metadata": {"icon": "timeline", "color": "#E91E63"},
            "params": [
                {"name": "a", "label": "Coefficient a", "unit": "", "min_value": -10.0, "max_value": 10.0, "default_value": 1.0},
                {"name": "b", "label": "Coefficient b", "unit": "", "min_value": -20.0, "max_value": 20.0, "default_value": 0.0},
                {"name": "c", "label": "Coefficient c", "unit": "", "min_value": -20.0, "max_value": 20.0, "default_value": -4.0},
            ],
        },
        {
            "title": "Pythagoras Theorem",
            "description": "Verify and explore the Pythagorean theorem for right-angled triangles.",
            "subject": "mathematics",
            "topic": "pythagorean",
            "difficulty": "beginner",
            "grade_min": 8,
            "grade_max": 9,
            "module_metadata": {"icon": "change_history", "color": "#FF9800"},
            "params": [
                {"name": "side_a", "label": "Side a", "unit": "units", "min_value": 0.01, "max_value": 1000.0, "default_value": 3.0},
                {"name": "side_b", "label": "Side b", "unit": "units", "min_value": 0.01, "max_value": 1000.0, "default_value": 4.0},
            ],
        },
        {
            "title": "Trigonometry",
            "description": "Calculate sin, cos, and tan for any angle and visualise the sine wave.",
            "subject": "mathematics",
            "topic": "trigonometry",
            "difficulty": "intermediate",
            "grade_min": 10,
            "grade_max": 11,
            "module_metadata": {"icon": "waves", "color": "#673AB7"},
            "params": [
                {"name": "angle_degrees", "label": "Angle", "unit": "°", "min_value": 0.0, "max_value": 360.0, "default_value": 30.0},
            ],
        },
        {
            "title": "Area of Circle",
            "description": "Calculate and visualise how area and circumference change with radius.",
            "subject": "mathematics",
            "topic": "area_circle",
            "difficulty": "beginner",
            "grade_min": 6,
            "grade_max": 8,
            "module_metadata": {"icon": "circle", "color": "#8BC34A"},
            "params": [
                {"name": "radius", "label": "Radius", "unit": "m", "min_value": 0.01, "max_value": 1000.0, "default_value": 5.0},
            ],
        },
        {
            "title": "Simple Interest",
            "description": "Calculate simple interest and total amount over time for given principal and rate.",
            "subject": "mathematics",
            "topic": "simple_interest",
            "difficulty": "beginner",
            "grade_min": 7,
            "grade_max": 9,
            "module_metadata": {"icon": "currency_rupee", "color": "#FF5722"},
            "params": [
                {"name": "principal", "label": "Principal", "unit": "INR", "min_value": 1.0, "max_value": 10000000.0, "default_value": 10000.0},
                {"name": "rate", "label": "Rate", "unit": "%", "min_value": 0.01, "max_value": 50.0, "default_value": 8.0},
                {"name": "time", "label": "Time", "unit": "years", "min_value": 0.1, "max_value": 50.0, "default_value": 2.0},
            ],
        },
        # ── Chemistry ────────────────────────────────────────────────────
        {
            "title": "Ideal Gas Law",
            "description": "Explore the Ideal Gas Law PV = nRT and how gas volume changes with temperature.",
            "subject": "chemistry",
            "topic": "ideal_gas",
            "difficulty": "advanced",
            "grade_min": 11,
            "grade_max": 12,
            "module_metadata": {"icon": "science", "color": "#00ACC1"},
            "params": [
                {"name": "pressure", "label": "Pressure", "unit": "Pa", "min_value": 1.0, "max_value": 10000000.0, "default_value": 101325.0},
                {"name": "moles", "label": "Moles", "unit": "mol", "min_value": 0.001, "max_value": 1000.0, "default_value": 1.0},
                {"name": "temperature", "label": "Temperature", "unit": "K", "min_value": 1.0, "max_value": 5000.0, "default_value": 300.0},
            ],
        },
    ]

    async with AsyncSessionLocal() as db:
        added_count = 0
        updated_count = 0
        for mod_data in MODULES_SEED:
            result = await db.execute(
                select(SimulationModule)
                .options(selectinload(SimulationModule.parameters))
                .where(SimulationModule.title == mod_data["title"])
            )
            existing = result.scalars().first()

            if existing is not None:
                # Ensure it's published and topic/subject are up to date
                changed = False
                if not existing.is_published:
                    existing.is_published = True
                    changed = True
                if existing.topic != mod_data["topic"]:
                    existing.topic = mod_data["topic"]
                    changed = True
                if existing.subject != mod_data["subject"]:
                    existing.subject = mod_data["subject"]
                    changed = True
                if changed:
                    updated_count += 1
                    logger.info("seed_module_updated", title=mod_data["title"])
                continue

            module = SimulationModule(
                title=mod_data["title"],
                description=mod_data["description"],
                subject=mod_data["subject"],
                topic=mod_data["topic"],
                difficulty=mod_data["difficulty"],
                grade_min=mod_data["grade_min"],
                grade_max=mod_data["grade_max"],
                is_published=True,
                module_metadata=mod_data.get("module_metadata", {}),
            )
            db.add(module)
            await db.flush([module])

            for p_data in mod_data["params"]:
                param = ModuleParameter(
                    module_id=module.id,
                    name=p_data["name"],
                    label=p_data["label"],
                    unit=p_data.get("unit", ""),
                    param_type="float",
                    min_value=p_data.get("min_value"),
                    max_value=p_data.get("max_value"),
                    step=0.1,
                    default_value=p_data.get("default_value", 0.0),
                    is_required=True,
                )
                db.add(param)

            added_count += 1
            logger.info("seed_module_added", title=mod_data["title"])

        await db.commit()
        logger.info("seed_completed", modules_added=added_count, modules_updated=updated_count)


# ---------------------------------------------------------------------------
# App factory
# ---------------------------------------------------------------------------


def create_app() -> FastAPI:
    app = FastAPI(
        title="Conceptra API",
        version="1.0.0",
        description=(
            "Interactive education visualization platform for Indian school students "
            "(Classes 6–12). Phase 0 MVP."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # ------------------------------------------------------------------
    # Custom middleware
    # NOTE: Starlette applies middleware in reverse-add order — the LAST
    # added middleware becomes the OUTERMOST (runs first on every request).
    # We add CORSMiddleware last so it is always outermost and attaches
    # CORS headers to every response, including raw 500s from our logging
    # middleware and any unhandled exceptions.
    # ------------------------------------------------------------------
    app.add_middleware(CorrelationIDMiddleware)
    app.add_middleware(RequestLoggingMiddleware)

    # ------------------------------------------------------------------
    # CORS - added LAST so it wraps everything and is truly outermost.
    # Always honor ALLOWED_ORIGINS from environment. In non-production,
    # additionally allow localhost:<port> for developer convenience.
    # ------------------------------------------------------------------
    cors_kwargs = dict(
        allow_origins=settings.get_allowed_origins(),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Correlation-ID"],
    )
    if not settings.IS_PRODUCTION:
        cors_kwargs["allow_origin_regex"] = r"http://(localhost|127\.0\.0\.1)(:\d+)?"
    app.add_middleware(CORSMiddleware, **cors_kwargs)

    # ------------------------------------------------------------------
    # Prometheus instrumentation
    # ------------------------------------------------------------------
    try:
        from prometheus_fastapi_instrumentator import Instrumentator

        instrumentator = Instrumentator(
            should_group_status_codes=True,
            should_ignore_untemplated=True,
            excluded_handlers=["/metrics", "/health"],
        )
        instrumentator.instrument(app)

        @app.get("/metrics", include_in_schema=False)
        async def metrics():
            from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
            from starlette.responses import Response

            return Response(
                content=generate_latest(),
                media_type=CONTENT_TYPE_LATEST,
            )

        instrumentator.expose(app, include_in_schema=False, endpoint="/metrics-auto")

    except ImportError:
        logger.warning("prometheus_not_available")

    # ------------------------------------------------------------------
    # Routers
    # ------------------------------------------------------------------
    from app.api.v1 import admin, analytics, auth, health, modules, progress, simulations

    app.include_router(health.router, prefix="/api/v1")
    app.include_router(auth.router, prefix="/api/v1")
    app.include_router(modules.router, prefix="/api/v1")
    app.include_router(simulations.router, prefix="/api/v1")
    app.include_router(progress.router, prefix="/api/v1")
    app.include_router(analytics.router, prefix="/api/v1")
    app.include_router(admin.router, prefix="/api/v1")

    # ------------------------------------------------------------------
    # Global exception handler
    # ------------------------------------------------------------------
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        logger.error(
            "unhandled_exception",
            path=request.url.path,
            method=request.method,
            error=str(exc),
            traceback=traceback.format_exc(),
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "An unexpected error occurred. Please try again later.",
                },
            },
        )

    return app


app = create_app()
