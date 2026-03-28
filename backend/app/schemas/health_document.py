"""Schemas for health documents (medical records & exam reports)."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


# ── Health Summary ──

class HealthSummaryOut(BaseModel):
    summary_text: str
    updated_at: datetime | None = None


# ── Health Document ──

class HealthDocumentOut(BaseModel):
    id: str
    doc_type: str
    source_type: str
    name: str
    hospital: str | None = None
    doc_date: str | None = None
    csv_data: dict | None = None
    abnormal_flags: list | None = None
    extraction_status: str
    created_at: datetime


class HealthDocumentCreate(BaseModel):
    """Manual creation (for non-photo uploads where user provides name)."""
    doc_type: str = Field(pattern=r"^(record|exam)$")
    name: str = Field(min_length=1, max_length=256)
    hospital: str | None = None
    doc_date: str | None = None  # ISO date string


class UploadPhotoRequest(BaseModel):
    doc_type: str = Field(pattern=r"^(record|exam)$")


class HealthDocumentListOut(BaseModel):
    items: list[HealthDocumentOut]
    total: int
