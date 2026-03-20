"""
EduViz database seed script.

Seeds the Speed simulation module and its parameters if the table is empty.

Usage:
    python seed_data.py
    # or from the project root:
    python backend/seed_data.py
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

# Ensure the backend package is importable when running as a standalone script
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import select

from app.core.config import settings
from app.core.logging_config import get_logger, setup_logging
from app.db.models import ModuleParameter, SimulationModule
from app.db.session import AsyncSessionLocal

setup_logging(log_level="INFO", json_logs=False)
logger = get_logger(__name__)


SPEED_MODULE = {
    "title": "Speed Simulation",
    "description": (
        "Explore the relationship between distance, time, and speed. "
        "Suitable for Classes 6–8 (Physics / Motion chapter)."
    ),
    "subject": "physics",
    "topic": "speed",
    "difficulty": "beginner",
    "grade_min": 6,
    "grade_max": 8,
    "is_published": True,
    "metadata": {"icon": "speedometer", "color": "#4CAF50", "phase": 0},
}

SPEED_PARAMETERS = [
    {
        "name": "distance",
        "label": "Distance",
        "unit": "m",
        "param_type": "float",
        "min_value": 0.1,
        "max_value": 10_000.0,
        "step": 0.1,
        "default_value": 100.0,
        "is_required": True,
    },
    {
        "name": "time",
        "label": "Time",
        "unit": "s",
        "param_type": "float",
        "min_value": 0.1,
        "max_value": 3_600.0,
        "step": 0.1,
        "default_value": 10.0,
        "is_required": True,
    },
]

ACCELERATION_MODULE = {
    "title": "Acceleration Simulation",
    "description": (
        "Investigate how initial velocity, final velocity, and time determine acceleration. "
        "Suitable for Classes 9–10 (Physics / Laws of Motion)."
    ),
    "subject": "physics",
    "topic": "acceleration",
    "difficulty": "intermediate",
    "grade_min": 9,
    "grade_max": 10,
    "is_published": True,
    "metadata": {"icon": "chart-line", "color": "#2196F3", "phase": 0},
}

ACCELERATION_PARAMETERS = [
    {
        "name": "initial_velocity",
        "label": "Initial Velocity",
        "unit": "m/s",
        "param_type": "float",
        "min_value": 0.0,
        "max_value": 1000.0,
        "step": 0.1,
        "default_value": 0.0,
        "is_required": True,
    },
    {
        "name": "final_velocity",
        "label": "Final Velocity",
        "unit": "m/s",
        "param_type": "float",
        "min_value": 0.0,
        "max_value": 1000.0,
        "step": 0.1,
        "default_value": 20.0,
        "is_required": True,
    },
    {
        "name": "time",
        "label": "Time",
        "unit": "s",
        "param_type": "float",
        "min_value": 0.1,
        "max_value": 3600.0,
        "step": 0.1,
        "default_value": 5.0,
        "is_required": True,
    },
]

FORCE_MODULE = {
    "title": "Force (Newton's 2nd Law)",
    "description": (
        "Calculate force using Newton's second law: F = ma. "
        "Suitable for Classes 9–10 (Physics / Laws of Motion)."
    ),
    "subject": "physics",
    "topic": "force",
    "difficulty": "intermediate",
    "grade_min": 9,
    "grade_max": 10,
    "is_published": True,
    "metadata": {"icon": "atom", "color": "#FF5722", "phase": 0},
}

FORCE_PARAMETERS = [
    {
        "name": "mass",
        "label": "Mass",
        "unit": "kg",
        "param_type": "float",
        "min_value": 0.001,
        "max_value": 100_000.0,
        "step": 0.001,
        "default_value": 10.0,
        "is_required": True,
    },
    {
        "name": "acceleration",
        "label": "Acceleration",
        "unit": "m/s²",
        "param_type": "float",
        "min_value": -1000.0,
        "max_value": 1000.0,
        "step": 0.01,
        "default_value": 9.8,
        "is_required": True,
    },
]

LINEAR_EQ_MODULE = {
    "title": "Linear Equation Graph",
    "description": (
        "Visualise the straight-line graph y = mx + c by adjusting slope (m) "
        "and intercept (c). Suitable for Classes 8–10 (Mathematics / Coordinate Geometry)."
    ),
    "subject": "math",
    "topic": "linear_equation",
    "difficulty": "beginner",
    "grade_min": 8,
    "grade_max": 10,
    "is_published": True,
    "metadata": {"icon": "function", "color": "#9C27B0", "phase": 0},
}

LINEAR_EQ_PARAMETERS = [
    {
        "name": "slope",
        "label": "Slope (m)",
        "unit": None,
        "param_type": "float",
        "min_value": -100.0,
        "max_value": 100.0,
        "step": 0.1,
        "default_value": 2.0,
        "is_required": True,
    },
    {
        "name": "intercept",
        "label": "Y-Intercept (c)",
        "unit": None,
        "param_type": "float",
        "min_value": -100.0,
        "max_value": 100.0,
        "step": 0.1,
        "default_value": 1.0,
        "is_required": True,
    },
]

SEED_MODULES = [
    (SPEED_MODULE, SPEED_PARAMETERS),
    (ACCELERATION_MODULE, ACCELERATION_PARAMETERS),
    (FORCE_MODULE, FORCE_PARAMETERS),
    (LINEAR_EQ_MODULE, LINEAR_EQ_PARAMETERS),
]


async def seed() -> None:
    """Insert seed modules if the simulation_modules table is empty."""
    async with AsyncSessionLocal() as db:
        existing = (await db.execute(select(SimulationModule).limit(1))).scalars().first()
        if existing is not None:
            logger.info("seed_skipped", reason="modules table already has data")
            return

        for module_data, param_list in SEED_MODULES:
            module = SimulationModule(**module_data)
            db.add(module)
            await db.flush([module])

            for pd in param_list:
                param = ModuleParameter(module_id=module.id, **pd)
                db.add(param)

            logger.info("seed_module_added", title=module.title, topic=module.topic)

        await db.commit()
        logger.info("seed_completed", total_modules=len(SEED_MODULES))


if __name__ == "__main__":
    asyncio.run(seed())
