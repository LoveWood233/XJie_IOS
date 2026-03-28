"""Service for writing activity logs (fire-and-forget style)."""
from __future__ import annotations

import logging

from sqlalchemy.orm import Session

from app.models.activity_log import ActivityLog

logger = logging.getLogger(__name__)


def log_activity(
    db: Session,
    user_id: int,
    action: str,
    detail: dict | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> None:
    """Insert an activity log row. Best-effort — swallows exceptions."""
    try:
        entry = ActivityLog(
            user_id=user_id,
            action=action,
            detail=detail or {},
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.add(entry)
        db.commit()
    except Exception:  # noqa: BLE001
        logger.exception("Failed to write activity log for user=%s action=%s", user_id, action)
        db.rollback()
