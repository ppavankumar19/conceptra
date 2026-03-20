"""
Physics and mathematics computation engines.

Each engine exposes a ``compute(**params) -> dict`` method returning:
  - result      : {"value": float, "unit": str, "label": str, ...extra}
  - explanation : {"formula": str, "substitution": str, "conclusion": str}
  - graph_data  : list of {"x": float, "y": float} dicts

``ComputationRouter`` dispatches to the correct engine by topic name.
"""

from __future__ import annotations

import math
from typing import Any

from fastapi import HTTPException, status


def _pts(x_vals: list[float], y_vals: list[float]) -> list[dict]:
    return [{"x": round(x, 6), "y": round(y, 6)} for x, y in zip(x_vals, y_vals)]


def _linspace(start: float, end: float, n: int = 11) -> list[float]:
    if n < 2:
        return [start]
    step = (end - start) / (n - 1)
    return [round(start + i * step, 6) for i in range(n)]


# ── Physics ────────────────────────────────────────────────────────────────


class SpeedEngine:
    TOPIC = "speed"

    def compute(self, distance: float, time: float) -> dict[str, Any]:
        if time <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Time must be greater than zero."})
        if distance < 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Distance cannot be negative."})
        speed = distance / time
        t_vals = _linspace(0, time)
        graph_data = _pts(t_vals, [round(speed * t, 6) for t in t_vals])
        return {
            "result": {"value": round(speed, 4), "unit": "m/s", "label": "Speed"},
            "explanation": {
                "formula": "speed = distance ÷ time",
                "substitution": f"speed = {distance} ÷ {time}",
                "conclusion": f"The object travels at {speed:.2f} m/s.",
            },
            "graph_data": graph_data,
        }


class AccelerationEngine:
    TOPIC = "acceleration"

    def compute(self, initial_velocity: float, final_velocity: float, time: float) -> dict[str, Any]:
        if time <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Time must be greater than zero."})
        acceleration = (final_velocity - initial_velocity) / time
        t_vals = _linspace(0, time)
        v_vals = [round(initial_velocity + acceleration * t, 6) for t in t_vals]
        return {
            "result": {"value": round(acceleration, 4), "unit": "m/s²", "label": "Acceleration"},
            "explanation": {
                "formula": "acceleration = (v_f − v_i) ÷ time",
                "substitution": f"acceleration = ({final_velocity} − {initial_velocity}) ÷ {time}",
                "conclusion": f"The acceleration is {acceleration:.2f} m/s².",
            },
            "graph_data": _pts(t_vals, v_vals),
        }


class ForceEngine:
    TOPIC = "force"

    def compute(self, mass: float, acceleration: float) -> dict[str, Any]:
        if mass <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Mass must be positive."})
        force = mass * acceleration
        a_max = max(abs(acceleration), 10.0)
        a_vals = _linspace(0, a_max)
        return {
            "result": {"value": round(force, 4), "unit": "N", "label": "Force"},
            "explanation": {
                "formula": "F = mass × acceleration",
                "substitution": f"F = {mass} × {acceleration}",
                "conclusion": f"The force on the object is {force:.2f} N.",
            },
            "graph_data": _pts(a_vals, [round(mass * a, 6) for a in a_vals]),
        }


class WorkEnergyEngine:
    TOPIC = "work_energy"

    def compute(self, force: float, displacement: float, angle_degrees: float = 0.0) -> dict[str, Any]:
        if displacement < 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Displacement cannot be negative."})
        angle_rad = math.radians(angle_degrees)
        work = force * displacement * math.cos(angle_rad)
        d_vals = _linspace(0, max(displacement, 1.0))
        w_vals = [round(force * d * math.cos(angle_rad), 6) for d in d_vals]
        return {
            "result": {"value": round(work, 4), "unit": "J", "label": "Work Done"},
            "explanation": {
                "formula": "W = F × d × cos(θ)",
                "substitution": f"W = {force} × {displacement} × cos({angle_degrees}°)",
                "conclusion": f"Work done by the force is {work:.2f} Joules.",
            },
            "graph_data": _pts(d_vals, w_vals),
        }


class PressureEngine:
    TOPIC = "pressure"

    def compute(self, force: float, area: float) -> dict[str, Any]:
        if area <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Area must be positive."})
        pressure = force / area
        a_vals = _linspace(0.01, max(area * 2, 1.0))
        p_vals = [round(force / a, 6) for a in a_vals]
        return {
            "result": {"value": round(pressure, 4), "unit": "Pa", "label": "Pressure"},
            "explanation": {
                "formula": "P = F ÷ A",
                "substitution": f"P = {force} ÷ {area}",
                "conclusion": f"The pressure exerted is {pressure:.2f} Pascals.",
            },
            "graph_data": _pts(a_vals, p_vals),
        }


class DensityEngine:
    TOPIC = "density"

    def compute(self, mass: float, volume: float) -> dict[str, Any]:
        if volume <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Volume must be positive."})
        if mass <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Mass must be positive."})
        density = mass / volume
        v_vals = _linspace(0.1, max(volume * 2, 1.0))
        m_vals = [round(density * v, 6) for v in v_vals]
        return {
            "result": {"value": round(density, 4), "unit": "kg/m³", "label": "Density"},
            "explanation": {
                "formula": "ρ = mass ÷ volume",
                "substitution": f"ρ = {mass} ÷ {volume}",
                "conclusion": f"The density of the substance is {density:.2f} kg/m³.",
            },
            "graph_data": _pts(v_vals, m_vals),
        }


class OhmsLawEngine:
    TOPIC = "ohms_law"

    def compute(self, voltage: float, resistance: float) -> dict[str, Any]:
        if resistance <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Resistance must be positive."})
        current = voltage / resistance
        v_vals = _linspace(0, max(voltage * 1.5, 10.0))
        i_vals = [round(v / resistance, 6) for v in v_vals]
        return {
            "result": {"value": round(current, 4), "unit": "A", "label": "Current"},
            "explanation": {
                "formula": "I = V ÷ R",
                "substitution": f"I = {voltage} ÷ {resistance}",
                "conclusion": f"The current flowing through the circuit is {current:.4f} A ({current*1000:.2f} mA).",
            },
            "graph_data": _pts(v_vals, i_vals),
        }


class PendulumEngine:
    TOPIC = "pendulum"

    def compute(self, length: float, gravity: float = 9.8) -> dict[str, Any]:
        if length <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Length must be positive."})
        if gravity <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Gravity must be positive."})
        period = 2 * math.pi * math.sqrt(length / gravity)
        l_vals = _linspace(0.1, max(length * 2, 1.0))
        t_vals = [round(2 * math.pi * math.sqrt(l / gravity), 6) for l in l_vals]
        return {
            "result": {"value": round(period, 4), "unit": "s", "label": "Time Period"},
            "explanation": {
                "formula": "T = 2π × √(L ÷ g)",
                "substitution": f"T = 2π × √({length} ÷ {gravity})",
                "conclusion": f"The pendulum completes one full oscillation in {period:.3f} seconds.",
            },
            "graph_data": _pts(l_vals, t_vals),
        }


class ProjectileEngine:
    TOPIC = "projectile"

    def compute(self, initial_velocity: float, angle_degrees: float, gravity: float = 9.8) -> dict[str, Any]:
        if initial_velocity <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Initial velocity must be positive."})
        if not (0 < angle_degrees < 90):
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Angle must be between 0° and 90°."})
        angle_rad = math.radians(angle_degrees)
        vx = initial_velocity * math.cos(angle_rad)
        vy = initial_velocity * math.sin(angle_rad)
        time_of_flight = 2 * vy / gravity
        max_range = vx * time_of_flight
        max_height = (vy ** 2) / (2 * gravity)
        # Trajectory graph: x vs y
        t_vals = _linspace(0, time_of_flight, 21)
        x_vals = [round(vx * t, 4) for t in t_vals]
        y_vals = [round(vy * t - 0.5 * gravity * t ** 2, 4) for t in t_vals]
        return {
            "result": {"value": round(max_range, 4), "unit": "m", "label": "Range"},
            "explanation": {
                "formula": "Range = v₀² × sin(2θ) ÷ g",
                "substitution": f"Range = {initial_velocity}² × sin(2×{angle_degrees}°) ÷ {gravity}",
                "conclusion": (
                    f"Range = {max_range:.2f} m, Max Height = {max_height:.2f} m, "
                    f"Time of Flight = {time_of_flight:.2f} s."
                ),
            },
            "graph_data": _pts(x_vals, y_vals),
        }


class GravitationalForceEngine:
    TOPIC = "gravitational_force"
    G = 6.674e-11

    def compute(self, mass1: float, mass2: float, distance: float) -> dict[str, Any]:
        if distance <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Distance must be positive."})
        force = self.G * mass1 * mass2 / (distance ** 2)
        d_vals = _linspace(distance * 0.5, distance * 3, 11)
        f_vals = [round(self.G * mass1 * mass2 / (d ** 2), 10) for d in d_vals]
        return {
            "result": {"value": round(force, 10), "unit": "N", "label": "Gravitational Force"},
            "explanation": {
                "formula": "F = G × m₁ × m₂ ÷ r²",
                "substitution": f"F = {self.G:.3e} × {mass1} × {mass2} ÷ {distance}²",
                "conclusion": f"The gravitational attraction between the masses is {force:.3e} N.",
            },
            "graph_data": _pts(d_vals, f_vals),
        }


# ── Mathematics ────────────────────────────────────────────────────────────


class LinearEquationEngine:
    TOPIC = "linear_equation"

    def compute(self, slope: float, intercept: float) -> dict[str, Any]:
        x_vals = _linspace(-10, 10, 21)
        y_vals = [round(slope * x + intercept, 6) for x in x_vals]
        sign = "+" if intercept >= 0 else "−"
        eq = f"y = {slope}x {sign} {abs(intercept)}"
        return {
            "result": {"value": round(slope, 4), "unit": "", "label": "Slope (m)"},
            "explanation": {
                "formula": "y = mx + c",
                "substitution": eq,
                "conclusion": (
                    f"The line has slope {slope} and y-intercept {intercept}. "
                    f"For every 1-unit increase in x, y changes by {slope}."
                ),
            },
            "graph_data": _pts(x_vals, y_vals),
        }


class QuadraticEngine:
    TOPIC = "quadratic"

    def compute(self, a: float, b: float, c: float) -> dict[str, Any]:
        if a == 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Coefficient 'a' cannot be zero (use linear equation instead)."})
        discriminant = b ** 2 - 4 * a * c
        vertex_x = -b / (2 * a)
        vertex_y = a * vertex_x ** 2 + b * vertex_x + c
        x_vals = _linspace(vertex_x - 5, vertex_x + 5, 21)
        y_vals = [round(a * x ** 2 + b * x + c, 4) for x in x_vals]
        if discriminant > 0:
            root_info = f"Two real roots: x = {(-b + math.sqrt(discriminant))/(2*a):.2f} and x = {(-b - math.sqrt(discriminant))/(2*a):.2f}"
        elif discriminant == 0:
            root_info = f"One real root: x = {vertex_x:.2f}"
        else:
            root_info = "No real roots (complex roots)"
        sign_b = "+" if b >= 0 else "−"
        sign_c = "+" if c >= 0 else "−"
        return {
            "result": {"value": round(vertex_y, 4), "unit": "", "label": "Vertex Y"},
            "explanation": {
                "formula": "y = ax² + bx + c",
                "substitution": f"y = {a}x² {sign_b} {abs(b)}x {sign_c} {abs(c)}",
                "conclusion": f"Vertex at ({vertex_x:.2f}, {vertex_y:.2f}). {root_info}.",
            },
            "graph_data": _pts(x_vals, y_vals),
        }


class PythagoreanEngine:
    TOPIC = "pythagorean"

    def compute(self, side_a: float, side_b: float) -> dict[str, Any]:
        if side_a <= 0 or side_b <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Both sides must be positive."})
        hypotenuse = math.sqrt(side_a ** 2 + side_b ** 2)
        # Graph: varying side_a while keeping side_b fixed
        a_vals = _linspace(0.5, max(side_a * 2, 5.0))
        c_vals = [round(math.sqrt(a ** 2 + side_b ** 2), 6) for a in a_vals]
        return {
            "result": {"value": round(hypotenuse, 4), "unit": "units", "label": "Hypotenuse"},
            "explanation": {
                "formula": "c = √(a² + b²)",
                "substitution": f"c = √({side_a}² + {side_b}²) = √({side_a**2 + side_b**2:.2f})",
                "conclusion": f"The hypotenuse is {hypotenuse:.4f} units.",
            },
            "graph_data": _pts(a_vals, c_vals),
        }


class TrigonometryEngine:
    TOPIC = "trigonometry"

    def compute(self, angle_degrees: float) -> dict[str, Any]:
        angle_rad = math.radians(angle_degrees)
        sin_val = round(math.sin(angle_rad), 6)
        cos_val = round(math.cos(angle_rad), 6)
        tan_val = round(math.tan(angle_rad), 6) if abs(math.cos(angle_rad)) > 1e-9 else None
        # Graph: sin curve from 0 to 360
        x_vals = _linspace(0, 360, 37)
        y_vals = [round(math.sin(math.radians(x)), 6) for x in x_vals]
        return {
            "result": {"value": sin_val, "unit": "", "label": f"sin({angle_degrees}°)"},
            "explanation": {
                "formula": "sin(θ), cos(θ), tan(θ)",
                "substitution": f"θ = {angle_degrees}°",
                "conclusion": (
                    f"sin({angle_degrees}°) = {sin_val:.4f}, "
                    f"cos({angle_degrees}°) = {cos_val:.4f}"
                    + (f", tan({angle_degrees}°) = {tan_val:.4f}" if tan_val is not None else " (tan undefined)")
                    + "."
                ),
            },
            "graph_data": _pts(x_vals, y_vals),
        }


class AreaCircleEngine:
    TOPIC = "area_circle"

    def compute(self, radius: float) -> dict[str, Any]:
        if radius <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Radius must be positive."})
        area = math.pi * radius ** 2
        circumference = 2 * math.pi * radius
        r_vals = _linspace(0.1, max(radius * 2, 1.0))
        a_vals = [round(math.pi * r ** 2, 6) for r in r_vals]
        return {
            "result": {"value": round(area, 4), "unit": "m²", "label": "Area"},
            "explanation": {
                "formula": "A = π × r²",
                "substitution": f"A = π × {radius}² = π × {radius**2:.4f}",
                "conclusion": f"Area = {area:.4f} m², Circumference = {circumference:.4f} m.",
            },
            "graph_data": _pts(r_vals, a_vals),
        }


class SimpleInterestEngine:
    TOPIC = "simple_interest"

    def compute(self, principal: float, rate: float, time: float) -> dict[str, Any]:
        if principal <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Principal must be positive."})
        if rate < 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Rate cannot be negative."})
        if time <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Time must be positive."})
        si = (principal * rate * time) / 100
        amount = principal + si
        t_vals = _linspace(0, time)
        a_vals = [round(principal + (principal * rate * t) / 100, 4) for t in t_vals]
        return {
            "result": {"value": round(si, 4), "unit": "INR", "label": "Simple Interest"},
            "explanation": {
                "formula": "SI = (P x R x T) / 100",
                "substitution": f"SI = ({principal} x {rate} x {time}) / 100",
                "conclusion": f"Simple Interest = Rs {si:.2f}. Total Amount = Rs {amount:.2f}.",
            },
            "graph_data": _pts(t_vals, a_vals),
        }


# ── Chemistry ──────────────────────────────────────────────────────────────


class IdealGasEngine:
    TOPIC = "ideal_gas"
    R = 8.314  # J/(mol·K)

    def compute(self, pressure: float, moles: float, temperature: float) -> dict[str, Any]:
        if pressure <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Pressure must be positive."})
        if moles <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Moles must be positive."})
        if temperature <= 0:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETER", "message": "Temperature must be in Kelvin (> 0)."})
        volume = (moles * self.R * temperature) / pressure
        t_vals = _linspace(100, max(temperature * 2, 400))
        v_vals = [round((moles * self.R * t) / pressure, 6) for t in t_vals]
        return {
            "result": {"value": round(volume, 6), "unit": "m³", "label": "Volume"},
            "explanation": {
                "formula": "PV = nRT  →  V = nRT ÷ P",
                "substitution": f"V = {moles} × {self.R} × {temperature} ÷ {pressure}",
                "conclusion": f"The gas occupies {volume*1000:.4f} litres ({volume:.6f} m³) at {temperature} K.",
            },
            "graph_data": _pts(t_vals, v_vals),
        }


# ── Router ─────────────────────────────────────────────────────────────────

_ENGINES: dict[str, Any] = {
    e.TOPIC: e() for e in [
        SpeedEngine, AccelerationEngine, ForceEngine, WorkEnergyEngine,
        PressureEngine, DensityEngine, OhmsLawEngine, PendulumEngine,
        ProjectileEngine, GravitationalForceEngine,
        LinearEquationEngine, QuadraticEngine, PythagoreanEngine,
        TrigonometryEngine, AreaCircleEngine, SimpleInterestEngine,
        IdealGasEngine,
    ]
}


class ComputationRouter:
    def route(self, module_topic: str, parameters: dict[str, float]) -> dict[str, Any]:
        engine = _ENGINES.get(module_topic.lower())
        if engine is None:
            raise HTTPException(
                status_code=400,
                detail={
                    "code": "UNSUPPORTED_TOPIC",
                    "message": f"No computation engine for topic '{module_topic}'. Supported: {list(_ENGINES.keys())}",
                },
            )
        try:
            return engine.compute(**parameters)
        except HTTPException:
            raise
        except TypeError as exc:
            raise HTTPException(status_code=400, detail={"code": "INVALID_PARAMETERS", "message": f"Parameter mismatch for '{module_topic}': {exc}"}) from exc
        except Exception as exc:
            raise HTTPException(status_code=500, detail={"code": "COMPUTATION_ERROR", "message": f"Computation failed: {exc}"}) from exc


computation_router = ComputationRouter()
