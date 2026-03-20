"""
Redis caching service with typed helpers, key builders, and a decorator.

TTLs (seconds):
  modules:list    300   (5 min)
  modules:detail  600   (10 min)
  sim:result     1800   (30 min)
  user:profile    300   (5 min)
"""

from __future__ import annotations

import functools
import hashlib
import json
from collections.abc import Callable, Coroutine
from typing import Any

import redis.asyncio as aioredis

from app.core.config import settings
from app.core.logging_config import get_logger

logger = get_logger(__name__)

# ---------------------------------------------------------------------------
# TTL constants
# ---------------------------------------------------------------------------

TTL_MODULE_LIST = 300
TTL_MODULE_DETAIL = 600
TTL_SIM_RESULT = 1800
TTL_USER_PROFILE = 300

# ---------------------------------------------------------------------------
# Key builders
# ---------------------------------------------------------------------------


def key_module_list(filter_hash: str) -> str:
    return f"conceptra:modules:list:{filter_hash}"


def key_module_detail(module_id: str) -> str:
    return f"conceptra:modules:detail:{module_id}"


def key_sim_result(module_id: str, params_hash: str) -> str:
    return f"conceptra:sim:result:{module_id}:{params_hash}"


def key_user_profile(user_id: str) -> str:
    return f"conceptra:user:profile:{user_id}"


def make_hash(data: Any) -> str:
    """Stable SHA-256 hash of a JSON-serialisable value (dict, list, str …)."""
    raw = json.dumps(data, sort_keys=True, default=str)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


# ---------------------------------------------------------------------------
# CacheService
# ---------------------------------------------------------------------------


class CacheService:
    """
    Thin async wrapper around the aioredis client.

    A single shared instance is created at startup and injected where needed.
    """

    def __init__(self, redis_url: str = settings.REDIS_URL) -> None:
        self._client: aioredis.Redis = aioredis.from_url(
            redis_url,
            encoding="utf-8",
            decode_responses=True,
        )

    async def get(self, key: str) -> Any | None:
        """Return the deserialized value or None if the key doesn't exist."""
        try:
            raw = await self._client.get(key)
            if raw is None:
                return None
            return json.loads(raw)
        except Exception as exc:
            logger.warning("cache_get_error", key=key, error=str(exc))
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        """Serialize and store *value* with the given TTL (seconds)."""
        try:
            await self._client.set(key, json.dumps(value, default=str), ex=ttl)
        except Exception as exc:
            logger.warning("cache_set_error", key=key, error=str(exc))

    async def delete(self, key: str) -> None:
        """Delete a single key."""
        try:
            await self._client.delete(key)
        except Exception as exc:
            logger.warning("cache_delete_error", key=key, error=str(exc))

    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching a glob-style pattern. Returns the count deleted."""
        try:
            keys = [k async for k in self._client.scan_iter(match=pattern, count=100)]
            if keys:
                return await self._client.delete(*keys)
            return 0
        except Exception as exc:
            logger.warning("cache_delete_pattern_error", pattern=pattern, error=str(exc))
            return 0

    async def ping(self) -> bool:
        """Return True if Redis is reachable."""
        try:
            return await self._client.ping()
        except Exception:
            return False

    async def close(self) -> None:
        await self._client.aclose()


# Singleton used throughout the application
cache_service = CacheService()


# ---------------------------------------------------------------------------
# Decorator
# ---------------------------------------------------------------------------


def cache_response(
    key_fn: Callable[..., str],
    ttl: int = 300,
) -> Callable:
    """
    Async route-handler decorator that caches the JSON-serialisable return value.

    Usage::

        @router.get("/modules/{module_id}")
        @cache_response(key_fn=lambda module_id, **_: key_module_detail(module_id), ttl=TTL_MODULE_DETAIL)
        async def get_module(module_id: str, ...):
            ...

    The decorated coroutine must accept the same positional/keyword arguments
    that ``key_fn`` receives (minus the ones that are not serialisable, e.g. db).
    """

    def decorator(func: Callable[..., Coroutine]) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                cache_key = key_fn(*args, **kwargs)
            except Exception:
                # If key generation fails, skip cache entirely
                return await func(*args, **kwargs)

            cached = await cache_service.get(cache_key)
            if cached is not None:
                logger.debug("cache_hit", key=cache_key)
                return cached

            result = await func(*args, **kwargs)

            await cache_service.set(cache_key, result, ttl=ttl)
            return result

        return wrapper

    return decorator
