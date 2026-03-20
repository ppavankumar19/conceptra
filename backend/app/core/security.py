"""
JWT validation using PyJWT + cryptography.
Supports RS256 (Supabase default) and HS256.
"""

from __future__ import annotations

import time
from typing import Any

import httpx
import jwt as pyjwt
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicKey
from jwt.algorithms import RSAAlgorithm
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings
from app.core.logging_config import get_logger

logger = get_logger(__name__)

_jwks_cache: dict[str, Any] | None = None
_jwks_fetched_at: float = 0.0
_JWKS_CACHE_TTL = 3600


async def _fetch_jwks() -> dict[str, Any]:
    global _jwks_cache, _jwks_fetched_at
    now = time.monotonic()
    if _jwks_cache is not None and (now - _jwks_fetched_at) < _JWKS_CACHE_TTL:
        return _jwks_cache
    url = f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url)
        resp.raise_for_status()
        _jwks_cache = resp.json()
        _jwks_fetched_at = now
        logger.info("jwks_refreshed")
        return _jwks_cache


async def verify_supabase_jwt(token: str) -> dict[str, Any]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"code": "INVALID_TOKEN", "message": "Could not validate credentials"},
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        header = pyjwt.get_unverified_header(token)
        alg = header.get("alg", "HS256")

        kid = header.get("kid")

        if kid or alg in ("RS256", "RS384", "RS512", "ES256", "ES384", "ES512"):
            # Asymmetric key — verify via Supabase JWKS
            jwks = await _fetch_jwks()
            keys = {k["kid"]: k for k in jwks.get("keys", [])}
            if kid and kid not in keys:
                raise ValueError(f"No key found for kid={kid}")
            key_data = keys.get(kid) or (next(iter(keys.values())) if keys else None)
            if not key_data:
                raise ValueError("JWKS has no keys")
            jwk_alg = key_data.get("alg", alg)
            if jwk_alg.startswith("RS"):
                public_key: RSAPublicKey = RSAAlgorithm.from_jwk(key_data)
            elif jwk_alg.startswith("ES"):
                from jwt.algorithms import ECAlgorithm
                public_key = ECAlgorithm.from_jwk(key_data)
            else:
                raise ValueError(f"Unsupported JWKS algorithm: {jwk_alg}")
            payload = pyjwt.decode(
                token,
                public_key,
                algorithms=[jwk_alg],
                options={"verify_aud": False},
            )
        else:
            # HS256 — Supabase stores the JWT secret as base64; decode it first
            import base64
            secret = settings.SUPABASE_JWT_SECRET
            try:
                decoded_secret = base64.b64decode(secret)
                payload = pyjwt.decode(
                    token,
                    decoded_secret,
                    algorithms=["HS256"],
                    options={"verify_aud": False},
                )
            except Exception:
                # Fallback: use raw string bytes (non-base64 secret)
                payload = pyjwt.decode(
                    token,
                    secret.encode(),
                    algorithms=["HS256"],
                    options={"verify_aud": False},
                )

        user_id: str | None = payload.get("sub")
        if not user_id:
            raise credentials_exception

        role: str = (
            payload.get("role")
            or (payload.get("app_metadata") or {}).get("role")
            or "student"
        )
        # Supabase sets role="authenticated" in JWT — map to "student"
        if role == "authenticated":
            role = "student"

        payload["user_id"] = user_id
        payload["role"] = role
        return payload

    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("jwt_validation_failed", error=str(exc))
        raise credentials_exception


_bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> dict[str, Any]:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "MISSING_TOKEN", "message": "Authorization header is missing"},
            headers={"WWW-Authenticate": "Bearer"},
        )
    return await verify_supabase_jwt(credentials.credentials)


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> dict[str, Any] | None:
    """Returns the current user if a valid token is present, otherwise None."""
    if credentials is None:
        return None
    try:
        return await verify_supabase_jwt(credentials.credentials)
    except HTTPException:
        return None
