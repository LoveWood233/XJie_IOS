"""Health data router – AI summary, medical records, exam reports."""

from __future__ import annotations

import base64
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import select, func as sa_func
from sqlalchemy.orm import Session

from app.core.deps import get_current_user_id, get_db
from app.models.health_document import HealthDocument, HealthSummary
from app.schemas.health_document import (
    HealthDocumentListOut,
    HealthDocumentOut,
    HealthSummaryOut,
)

logger = logging.getLogger(__name__)
router = APIRouter()


# ─── Helper ──────────────────────────────────────────────

def _doc_to_out(doc: HealthDocument) -> HealthDocumentOut:
    return HealthDocumentOut(
        id=str(doc.id),
        doc_type=doc.doc_type,
        source_type=doc.source_type,
        name=doc.name,
        hospital=doc.hospital,
        doc_date=doc.doc_date.isoformat() if doc.doc_date else None,
        csv_data=doc.csv_data,
        abnormal_flags=doc.abnormal_flags,
        extraction_status=doc.extraction_status,
        created_at=doc.created_at,
    )


def _mock_extract_record(file_bytes: bytes, filename: str) -> dict:
    """Mock LLM extraction for medical records. Returns structured CSV data."""
    # TODO: Replace with real LLM call when API is configured
    return {
        "columns": ["项目", "内容"],
        "rows": [
            ["医院", "（待LLM提取）"],
            ["科室", "（待LLM提取）"],
            ["日期", "（待LLM提取）"],
            ["诊断", "（待LLM提取）"],
            ["症状描述", "（待LLM提取）"],
            ["用药方案", "（待LLM提取）"],
            ["医嘱", "（待LLM提取）"],
        ],
    }


def _mock_extract_exam(file_bytes: bytes, filename: str) -> tuple[dict, list]:
    """Mock LLM extraction for exam reports. Returns (csv_data, abnormal_flags)."""
    # TODO: Replace with real LLM call when API is configured
    csv_data = {
        "columns": ["检查项目", "数值", "单位", "参考范围", "异常"],
        "rows": [
            ["血红蛋白", "--", "g/L", "120-160", ""],
            ["白细胞", "--", "×10⁹/L", "4.0-10.0", ""],
            ["血小板", "--", "×10⁹/L", "100-300", ""],
            ["空腹血糖", "--", "mmol/L", "3.9-6.1", ""],
            ["总胆固醇", "--", "mmol/L", "2.8-5.2", ""],
            ["甘油三酯", "--", "mmol/L", "0.56-1.7", ""],
        ],
    }
    abnormal_flags = []  # TODO: LLM will populate this
    return csv_data, abnormal_flags


def _mock_extract_name(file_bytes: bytes, doc_type: str) -> str:
    """Mock LLM name extraction (hospital + date). Returns fallback."""
    # TODO: Replace with real LLM-based OCR extraction
    now = datetime.now().strftime("%Y-%m-%d")
    label = "病例" if doc_type == "record" else "体检报告"
    return f"未识别医院-{now}-{label}"


# ─── AI Summary ──────────────────────────────────────────

@router.get("/summary", response_model=HealthSummaryOut)
def get_summary(
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get latest AI health summary for user."""
    row = db.execute(
        select(HealthSummary)
        .where(HealthSummary.user_id == user_id)
        .order_by(HealthSummary.updated_at.desc())
        .limit(1)
    ).scalars().first()

    if row:
        return HealthSummaryOut(summary_text=row.summary_text, updated_at=row.updated_at)
    return HealthSummaryOut(summary_text="", updated_at=None)


@router.post("/summary/generate", response_model=HealthSummaryOut)
def generate_summary(
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Generate a new AI health summary from all user medical records & exam reports."""
    # Gather all documents for context
    docs = db.execute(
        select(HealthDocument)
        .where(HealthDocument.user_id == user_id)
        .order_by(HealthDocument.doc_date.desc().nulls_last())
    ).scalars().all()

    # TODO: Replace with real LLM call using docs as context
    if docs:
        record_count = sum(1 for d in docs if d.doc_type == "record")
        exam_count = sum(1 for d in docs if d.doc_type == "exam")
        summary_text = (
            f"基于您上传的 {record_count} 份病例和 {exam_count} 份体检报告进行综合分析：\n\n"
            f"📋 病例记录共 {record_count} 份\n"
            f"🔬 体检报告共 {exam_count} 份\n\n"
            f"⏳ AI 详细分析功能即将上线，当前为占位摘要。\n"
            f"上线后将自动结合您的所有病例和体检数据，生成个性化健康总结。"
        )
    else:
        summary_text = "暂无健康数据，请先上传病例或体检报告后再生成 AI 总结。"

    # Upsert summary
    existing = db.execute(
        select(HealthSummary).where(HealthSummary.user_id == user_id).limit(1)
    ).scalars().first()

    if existing:
        existing.summary_text = summary_text
        existing.updated_at = datetime.utcnow()
    else:
        existing = HealthSummary(user_id=user_id, summary_text=summary_text)
        db.add(existing)

    db.commit()
    db.refresh(existing)
    return HealthSummaryOut(summary_text=existing.summary_text, updated_at=existing.updated_at)


# ─── Document Upload ─────────────────────────────────────

@router.post("/upload", response_model=HealthDocumentOut)
def upload_document(
    file: UploadFile = File(...),
    doc_type: str = Form(..., pattern=r"^(record|exam)$"),
    name: str = Form(default=""),
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Upload a photo/CSV/PDF and extract structured data.

    For photo uploads, LLM auto-extracts name (hospital+date) and data.
    For CSV/PDF non-image uploads, `name` is required from user.
    """
    file_bytes = file.file.read()
    filename = file.filename or "unknown"
    content_type = file.content_type or ""

    is_image = content_type.startswith("image/") or filename.lower().endswith((".jpg", ".jpeg", ".png", ".heic"))

    # Determine source type
    if is_image:
        source_type = "photo"
    elif filename.lower().endswith(".csv"):
        source_type = "csv"
    elif filename.lower().endswith(".pdf"):
        source_type = "pdf"
    else:
        source_type = "photo"  # default

    # Auto-extract name for images, require manual for non-images
    if is_image:
        auto_name = _mock_extract_name(file_bytes, doc_type)
        doc_name = name or auto_name
    else:
        if not name:
            raise HTTPException(status_code=422, detail="非图片文件请提供文件名称（医院-时间）")
        doc_name = name

    # Store file as base64 in DB for simplicity (MVP)
    # TODO: Move to MinIO/OSS for production
    file_b64 = base64.b64encode(file_bytes).decode("ascii")

    # Extract structured data
    if doc_type == "record":
        csv_data = _mock_extract_record(file_bytes, filename)
        abnormal_flags = None
    else:
        csv_data, abnormal_flags = _mock_extract_exam(file_bytes, filename)

    doc = HealthDocument(
        user_id=user_id,
        doc_type=doc_type,
        source_type=source_type,
        name=doc_name,
        hospital=doc_name.split("-")[0] if "-" in doc_name else None,
        doc_date=datetime.utcnow(),
        original_file_path=f"data:base64:{filename}",  # placeholder
        csv_data=csv_data,
        abnormal_flags=abnormal_flags,
        extraction_status="done",
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)

    logger.info("Health document uploaded: type=%s, name=%s, user=%s", doc_type, doc_name, str(user_id)[:8])
    return _doc_to_out(doc)


# ─── Document List & Detail ──────────────────────────────

@router.get("/documents", response_model=HealthDocumentListOut)
def list_documents(
    doc_type: str | None = None,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """List documents, optionally filtered by doc_type ('record' or 'exam')."""
    q = select(HealthDocument).where(HealthDocument.user_id == user_id)
    if doc_type:
        q = q.where(HealthDocument.doc_type == doc_type)
    q = q.order_by(HealthDocument.doc_date.desc().nulls_last(), HealthDocument.created_at.desc())

    docs = db.execute(q).scalars().all()
    return HealthDocumentListOut(
        items=[_doc_to_out(d) for d in docs],
        total=len(docs),
    )


@router.get("/documents/{doc_id}", response_model=HealthDocumentOut)
def get_document(
    doc_id: str,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get a single document detail (with CSV data)."""
    doc = db.execute(
        select(HealthDocument).where(
            HealthDocument.id == int(doc_id),
            HealthDocument.user_id == user_id,
        )
    ).scalars().first()

    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return _doc_to_out(doc)


@router.delete("/documents/{doc_id}")
def delete_document(
    doc_id: str,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Delete a health document."""
    doc = db.execute(
        select(HealthDocument).where(
            HealthDocument.id == int(doc_id),
            HealthDocument.user_id == user_id,
        )
    ).scalars().first()

    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    db.delete(doc)
    db.commit()
    return {"ok": True}
