"""Structured JSON logging for production, human-readable for dev."""
from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone

from app.core.config import settings


class JSONFormatter(logging.Formatter):
    """Emit each log record as a single JSON line."""

    def format(self, record: logging.LogRecord) -> str:
        log_obj = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if record.exc_info and record.exc_info[0] is not None:
            log_obj["exception"] = self.formatException(record.exc_info)
        # Attach extra fields injected by middleware / manual logger calls
        for key in ("user_id", "method", "path", "status_code", "duration_ms", "request_id"):
            val = getattr(record, key, None)
            if val is not None:
                log_obj[key] = val
        return json.dumps(log_obj, ensure_ascii=False)


def setup_logging() -> None:
    root = logging.getLogger()
    root.setLevel(logging.INFO)

    # Remove existing handlers to avoid duplicates on hot-reload
    for h in root.handlers[:]:
        root.removeHandler(h)

    handler = logging.StreamHandler(sys.stdout)

    if settings.APP_ENV == "dev":
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s")
        )
    else:
        handler.setFormatter(JSONFormatter())

    root.addHandler(handler)

    # Quiet noisy libs
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
