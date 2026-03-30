from __future__ import annotations

from datetime import datetime
import os
import time
import uuid

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.audit import LLMAuditLog
from app.models.meal import MealPhoto, PhotoStatus
from app.providers.base import MealVisionResult
from app.providers.factory import get_provider
from app.services.inference_service import infer_meal_time_from_glucose
from app.utils.hash import context_hash


def generate_object_key(user_id: str, filename: str) -> str:
    ext = os.path.splitext(filename)[1].lower() or ".jpg"
    return f"meals/{user_id}/{uuid.uuid4().hex}{ext}"


def build_mock_upload_url(object_key: str) -> str:
    return f"/api/meals/photo/mock-upload/{object_key}"


def ensure_local_storage_path(object_key: str) -> str:
    path = os.path.join(settings.LOCAL_STORAGE_DIR, object_key)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def create_photo_record(db: Session, user_id: str, object_key: str, exif_ts: datetime | None) -> MealPhoto:
    photo = MealPhoto(user_id=user_id, image_object_key=object_key, exif_ts=exif_ts)
    db.add(photo)
    db.commit()
    db.refresh(photo)
    return photo


def process_photo_sync(db: Session, photo: MealPhoto) -> MealPhoto:
    provider = get_provider()
    image_url = f"{settings.S3_PUBLIC_BASE_URL.rstrip('/')}/{photo.image_object_key}"
    t0 = time.perf_counter()
    result = provider.analyze_image(image_url)
    latency_ms = int((time.perf_counter() - t0) * 1000)

    # Record audit for vision call
    audit = LLMAuditLog(
        user_id=int(photo.user_id),
        provider=provider.provider_name,
        model=provider.vision_model,
        feature="meal_vision",
        latency_ms=latency_ms,
        prompt_tokens=result.prompt_tokens,
        completion_tokens=result.completion_tokens,
        context_hash=context_hash({"image_key": photo.image_object_key}),
        meta={"photo_id": photo.id, "total_kcal": result.total_kcal},
    )
    db.add(audit)

    _update_photo_from_vision(photo, result)

    inferred_ts, inferred_conf = infer_meal_time_from_glucose(db, str(photo.user_id), photo.uploaded_at)
    if inferred_ts is not None:
        photo.vision_json = {
            **(photo.vision_json or {}),
            "inferred_meal_ts": inferred_ts.isoformat(),
            "inferred_confidence": inferred_conf,
        }

    db.add(photo)
    db.commit()
    db.refresh(photo)
    return photo


def _update_photo_from_vision(photo: MealPhoto, result: MealVisionResult) -> None:
    photo.status = PhotoStatus.processed
    photo.vision_json = result.model_dump()
    photo.calorie_estimate_kcal = result.total_kcal
    photo.confidence = result.confidence
