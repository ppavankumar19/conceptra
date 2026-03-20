"""Pydantic v2 schemas for simulation requests and responses."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class SimulateRequest(BaseModel):
    module_id: str
    parameters: dict[str, float]
    locale: str = Field("en", max_length=10)


class ExplanationSchema(BaseModel):
    formula: str
    substitution: str
    conclusion: str


class SimulateResponse(BaseModel):
    session_id: str
    module_id: str
    topic: str
    input_parameters: dict[str, float]
    result: dict[str, Any]
    result_value: float
    result_unit: str
    result_label: str
    explanation: ExplanationSchema
    graph_data: list[dict[str, float]] | None = None


class SimulationSessionHistory(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    module_id: str
    input_parameters: dict[str, Any]
    result: dict[str, Any]
    explanation: dict[str, Any] | None = None
    graph_data: list[Any] | None = None
    locale: str
    duration_ms: int | None = None
    created_at: datetime
