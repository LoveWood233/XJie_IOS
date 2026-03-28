"""FastAPI middleware for request/response logging and request-ID injection."""
from __future__ import annotations

import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("metabodash.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Log every request with method, path, status and duration. Inject request-id header."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("X-Request-ID", uuid.uuid4().hex[:16])
        start = time.perf_counter()

        # Extract user_id from Authorization header if present (best-effort, no validation)
        user_id: str | None = None
        auth = request.headers.get("authorization", "")
        if auth.startswith("Bearer "):
            try:
                import jwt  # noqa: PLC0415
                from app.core.config import settings  # noqa: PLC0415
                payload = jwt.decode(
                    auth.removeprefix("Bearer ").strip(),
                    settings.JWT_SECRET,
                    algorithms=["HS256"],
                    options={"verify_exp": False},
                )
                user_id = payload.get("sub")
            except Exception:  # noqa: BLE001
                pass

        response: Response = await call_next(request)

        duration_ms = round((time.perf_counter() - start) * 1000, 1)

        # Skip health checks from access log
        if request.url.path in ("/healthz", "/health"):
            response.headers["X-Request-ID"] = request_id
            return response

        logger.info(
            "%s %s → %s (%.1fms)",
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
            extra={
                "method": request.method,
                "path": str(request.url.path),
                "status_code": response.status_code,
                "duration_ms": duration_ms,
                "user_id": user_id,
                "request_id": request_id,
            },
        )

        response.headers["X-Request-ID"] = request_id
        return response
