"""
Tests for simulation endpoints.

POST /api/v1/simulate         – run computation
GET  /api/v1/simulate/history – user's session history
GET  /api/v1/simulate/{id}    – single session (owner-gated)
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.db.models import ModuleParameter, SimulationModule, UserProfile


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


async def _ensure_user(db: AsyncSession, uid: str, email: str) -> UserProfile:
    from sqlalchemy import select

    result = await db.execute(select(UserProfile).where(UserProfile.supabase_user_id == uid))
    profile = result.scalars().first()
    if profile is None:
        profile = UserProfile(supabase_user_id=uid, email=email, role="student")
        db.add(profile)
        await db.flush([profile])
    return profile


async def _create_speed_module(db: AsyncSession) -> SimulationModule:
    """Create and persist a published Speed module for tests."""
    module = SimulationModule(
        title="Speed Simulation",
        subject="physics",
        topic="speed",
        difficulty="beginner",
        grade_min=6,
        grade_max=8,
        is_published=True,
    )
    db.add(module)
    await db.flush([module])

    params = [
        ModuleParameter(
            module_id=module.id,
            name="distance",
            label="Distance",
            unit="m",
            param_type="float",
            min_value=0.1,
            max_value=10000.0,
            default_value=100.0,
            is_required=True,
        ),
        ModuleParameter(
            module_id=module.id,
            name="time",
            label="Time",
            unit="s",
            param_type="float",
            min_value=0.1,
            max_value=3600.0,
            default_value=10.0,
            is_required=True,
        ),
    ]
    for p in params:
        db.add(p)
    await db.flush()
    return module


# ---------------------------------------------------------------------------
# POST /simulate – valid computation
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_simulate_speed_valid(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """Valid speed computation returns correct result and explanation."""
    user_payload = {"sub": "sim-user-001", "email": "sim@test.com", "role": "student", "user_id": "sim-user-001"}
    app.dependency_overrides[get_current_user] = lambda: user_payload

    await _ensure_user(db_session, "sim-user-001", "sim@test.com")
    module = await _create_speed_module(db_session)

    try:
        response = await client.post(
            "/api/v1/simulate",
            json={
                "module_id": module.id,
                "parameters": {"distance": 100.0, "time": 10.0},
                "locale": "en",
            },
        )
        assert response.status_code == 200, response.text
        body = response.json()
        assert body["success"] is True
        data = body["data"]

        assert data["result"]["speed"] == pytest.approx(10.0, rel=1e-3)
        assert data["result"]["unit"] == "m/s"
        assert "formula" in data["explanation"]
        assert "substitution" in data["explanation"]
        assert "conclusion" in data["explanation"]
        assert isinstance(data["graph_data"], list)
        assert len(data["graph_data"]) > 0
        assert "session_id" in data
    finally:
        app.dependency_overrides.pop(get_current_user, None)


# ---------------------------------------------------------------------------
# POST /simulate – division by zero (time = 0)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_simulate_speed_division_by_zero(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """time=0 should return HTTP 400 with DIVISION_BY_ZERO code."""
    user_payload = {"sub": "sim-user-002", "email": "sim2@test.com", "role": "student", "user_id": "sim-user-002"}
    app.dependency_overrides[get_current_user] = lambda: user_payload

    await _ensure_user(db_session, "sim-user-002", "sim2@test.com")
    module = await _create_speed_module(db_session)

    # time=0 is below min_value=0.1, so it should fail parameter validation
    try:
        response = await client.post(
            "/api/v1/simulate",
            json={
                "module_id": module.id,
                "parameters": {"distance": 100.0, "time": 0.0},
            },
        )
        assert response.status_code == 400, response.text
        detail = response.json()["detail"]
        assert detail["code"] in ("PARAMETER_OUT_OF_RANGE", "DIVISION_BY_ZERO")
    finally:
        app.dependency_overrides.pop(get_current_user, None)


# ---------------------------------------------------------------------------
# POST /simulate – missing required parameter
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_simulate_missing_parameter(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """Omitting a required parameter should return HTTP 400."""
    user_payload = {"sub": "sim-user-003", "email": "sim3@test.com", "role": "student", "user_id": "sim-user-003"}
    app.dependency_overrides[get_current_user] = lambda: user_payload

    await _ensure_user(db_session, "sim-user-003", "sim3@test.com")
    module = await _create_speed_module(db_session)

    try:
        response = await client.post(
            "/api/v1/simulate",
            json={
                "module_id": module.id,
                "parameters": {"distance": 100.0},  # Missing 'time'
            },
        )
        assert response.status_code == 400, response.text
        detail = response.json()["detail"]
        assert detail["code"] == "MISSING_PARAMETER"
    finally:
        app.dependency_overrides.pop(get_current_user, None)


# ---------------------------------------------------------------------------
# POST /simulate – unknown parameter
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_simulate_unknown_parameter(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """Sending an unknown parameter key should return HTTP 400."""
    user_payload = {"sub": "sim-user-004", "email": "sim4@test.com", "role": "student", "user_id": "sim-user-004"}
    app.dependency_overrides[get_current_user] = lambda: user_payload

    await _ensure_user(db_session, "sim-user-004", "sim4@test.com")
    module = await _create_speed_module(db_session)

    try:
        response = await client.post(
            "/api/v1/simulate",
            json={
                "module_id": module.id,
                "parameters": {"distance": 100.0, "time": 10.0, "bogus": 99.0},
            },
        )
        assert response.status_code == 400, response.text
        detail = response.json()["detail"]
        assert detail["code"] == "UNKNOWN_PARAMETER"
    finally:
        app.dependency_overrides.pop(get_current_user, None)


# ---------------------------------------------------------------------------
# GET /simulate/history – returns only current user's sessions
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_simulation_history_isolation(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """History endpoint should only return the calling user's sessions."""
    # User A runs a simulation
    user_a = {"sub": "hist-user-A", "email": "hista@test.com", "role": "student", "user_id": "hist-user-A"}
    app.dependency_overrides[get_current_user] = lambda: user_a
    await _ensure_user(db_session, "hist-user-A", "hista@test.com")
    module = await _create_speed_module(db_session)

    await client.post(
        "/api/v1/simulate",
        json={"module_id": module.id, "parameters": {"distance": 50.0, "time": 5.0}},
    )

    # User B checks history – should see 0 sessions
    user_b = {"sub": "hist-user-B", "email": "histb@test.com", "role": "student", "user_id": "hist-user-B"}
    app.dependency_overrides[get_current_user] = lambda: user_b
    await _ensure_user(db_session, "hist-user-B", "histb@test.com")

    response = await client.get("/api/v1/simulate/history")
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["success"] is True
    assert body["meta"]["total"] == 0

    app.dependency_overrides.pop(get_current_user, None)


# ---------------------------------------------------------------------------
# GET /simulate/{session_id} – 403 for wrong user
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_session_forbidden_for_other_user(
    client: AsyncClient, app, db_session: AsyncSession
) -> None:
    """Accessing another user's session should return 403."""
    # User A creates a session
    user_a = {"sub": "owner-user-A", "email": "owner_a@test.com", "role": "student", "user_id": "owner-user-A"}
    app.dependency_overrides[get_current_user] = lambda: user_a
    await _ensure_user(db_session, "owner-user-A", "owner_a@test.com")
    module = await _create_speed_module(db_session)

    sim_resp = await client.post(
        "/api/v1/simulate",
        json={"module_id": module.id, "parameters": {"distance": 200.0, "time": 20.0}},
    )
    assert sim_resp.status_code == 200
    session_id = sim_resp.json()["data"]["session_id"]

    # User B tries to access User A's session
    user_b = {"sub": "thief-user-B", "email": "thief_b@test.com", "role": "student", "user_id": "thief-user-B"}
    app.dependency_overrides[get_current_user] = lambda: user_b
    await _ensure_user(db_session, "thief-user-B", "thief_b@test.com")

    response = await client.get(f"/api/v1/simulate/{session_id}")
    assert response.status_code == 403, response.text

    app.dependency_overrides.pop(get_current_user, None)
