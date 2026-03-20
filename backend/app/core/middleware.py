"""
Custom pure-ASGI middleware.

Using pure ASGI (implementing __call__ directly) instead of BaseHTTPMiddleware
avoids the greenlet incompatibility with asyncpg/SQLAlchemy async.
BaseHTTPMiddleware wraps calls via anyio.to_thread.run_sync, which creates a
different async execution context that breaks SQLAlchemy's greenlet-based driver.

- CorrelationIDMiddleware  : generates a UUID per request, exposes it via header,
                             stores it in a ContextVar for structured logging.
- RequestLoggingMiddleware : logs method, path, status code, and duration.
                             Also serves as the outermost safety net — any
                             exception that escapes all inner layers is caught
                             here and returned as a 500 JSON response so that
                             CORS headers (added by the inner CORSMiddleware)
                             are still delivered to the browser.
"""

from __future__ import annotations

import json
import time
from uuid import uuid4

from starlette.types import ASGIApp, Receive, Scope, Send

from app.core.logging_config import get_logger, set_correlation_id

logger = get_logger(__name__)

CORRELATION_ID_HEADER = "X-Correlation-ID"

_ERR_BODY = json.dumps(
    {"success": False, "error": {"code": "INTERNAL_SERVER_ERROR", "message": "An unexpected error occurred."}}
).encode()


class CorrelationIDMiddleware:
    """
    Reads or generates a correlation / trace ID for every HTTP request.

    Priority:
    1. ``X-Correlation-ID`` header sent by the client / upstream proxy.
    2. Freshly generated UUID4.

    The ID is:
    - Written back to the ContextVar so that all log records within the
      same async task include it automatically.
    - Added to the response as ``X-Correlation-ID``.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] not in ("http", "websocket"):
            await self.app(scope, receive, send)
            return

        # Extract correlation ID from request headers
        headers = dict(scope.get("headers", []))
        cid = (
            headers.get(b"x-correlation-id", b"").decode()
            or str(uuid4())
        )
        set_correlation_id(cid)

        cid_bytes = cid.encode()

        async def send_with_cid(message):
            if message["type"] == "http.response.start":
                # Inject correlation ID header into response
                headers_list = list(message.get("headers", []))
                headers_list.append((b"x-correlation-id", cid_bytes))
                message = {**message, "headers": headers_list}
            await send(message)

        await self.app(scope, receive, send_with_cid)


class RequestLoggingMiddleware:
    """
    Logs every HTTP request with method, path, status code, and elapsed time.

    This is the outermost middleware layer. It catches any exception that
    escapes all inner layers (route handlers, dependency cleanup, etc.) and
    returns a proper 500 JSON response instead of resetting the TCP connection.
    This guarantees that CORS headers (set by the inner CORSMiddleware) are
    always delivered to the browser even on unexpected server errors.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        start = time.perf_counter()
        method = scope.get("method", "")
        path = scope.get("path", "")
        query = scope.get("query_string", b"").decode()
        client = scope.get("client")
        client_ip = client[0] if client else None

        status_code = 0
        response_started = False

        async def send_capturing_status(message):
            nonlocal status_code, response_started
            if message["type"] == "http.response.start":
                status_code = message.get("status", 0)
                response_started = True
            await send(message)

        try:
            await self.app(scope, receive, send_capturing_status)
        except Exception as exc:  # noqa: BLE001
            logger.error(
                "unhandled_exception_in_middleware",
                method=method,
                path=path,
                error=str(exc),
            )
            if not response_started:
                # No response has been sent yet — return a 500 so the browser
                # receives a proper HTTP response with CORS headers from the
                # inner CORSMiddleware layer.
                await send_capturing_status({
                    "type": "http.response.start",
                    "status": 500,
                    "headers": [
                        (b"content-type", b"application/json"),
                        (b"content-length", str(len(_ERR_BODY)).encode()),
                    ],
                })
                await send_capturing_status({
                    "type": "http.response.body",
                    "body": _ERR_BODY,
                    "more_body": False,
                })

        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)

        log = logger.bind(
            method=method,
            path=path,
            query=query or None,
            status_code=status_code,
            duration_ms=elapsed_ms,
            client_ip=client_ip,
        )

        if status_code >= 500:
            log.error("http_request")
        elif status_code >= 400:
            log.warning("http_request")
        else:
            log.info("http_request")
