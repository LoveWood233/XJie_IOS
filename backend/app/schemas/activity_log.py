"""Schemas for activity logs."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class ActivityLogOut(BaseModel):
    id: str
    action: str
    detail: dict
    ip_address: str | None = None
    created_at: datetime


class ActivityLogPage(BaseModel):
    items: list[ActivityLogOut]
    total: int
    page: int
    page_size: int
