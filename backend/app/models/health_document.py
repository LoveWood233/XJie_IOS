"""Health document models – medical records & exam reports."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.compat import JSONB


class HealthSummary(Base):
    """AI-generated health summary, one active per user."""

    __tablename__ = "health_summaries"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), nullable=False, index=True)
    summary_text: Mapped[str] = mapped_column(Text, nullable=False, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)


class HealthDocument(Base):
    """Uploaded medical record or exam report.

    doc_type:
        - 'record'  → 历史病例
        - 'exam'    → 历史体检报告
    source_type:
        - 'photo'   → 拍照上传 (LLM extracts structured data)
        - 'csv'     → CSV 文件直接上传
        - 'pdf'     → PDF 文件上传
    """

    __tablename__ = "health_documents"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), nullable=False)
    doc_type: Mapped[str] = mapped_column(String(16), nullable=False)  # 'record' | 'exam'
    source_type: Mapped[str] = mapped_column(String(16), nullable=False)  # 'photo' | 'csv' | 'pdf'
    name: Mapped[str] = mapped_column(String(256), nullable=False, default="")  # e.g. "北京协和-2026-03-20"
    hospital: Mapped[str | None] = mapped_column(String(256), nullable=True)
    doc_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    original_file_path: Mapped[str | None] = mapped_column(Text, nullable=True)  # path to original photo/file
    csv_data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # extracted structured data
    abnormal_flags: Mapped[dict | None] = mapped_column(JSONB, nullable=True)  # for exam reports: [{field, value, ref_range, is_abnormal}]
    extraction_status: Mapped[str] = mapped_column(String(16), nullable=False, default="pending")  # pending | done | failed
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index("ix_health_doc_user_type", "user_id", "doc_type"),
        Index("ix_health_doc_user_date", "user_id", "doc_date"),
    )
