from __future__ import annotations

import json

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import get_current_user_id, get_db
from app.models.cgm_integration import CGMDeviceBinding
from app.schemas.cgm import CGMBindingCreate, CGMBindingOut, CGMIngestResponse
from app.services.cgm_service import ingest_cgm_records, parse_cgm_payload, verify_signature

router = APIRouter()


def _to_binding_out(row: CGMDeviceBinding) -> CGMBindingOut:
    return CGMBindingOut(
        id=str(row.id),
        provider=row.provider,
        phone=row.phone,
        device_sn=row.device_sn,
        device_id=row.device_id,
        is_active=row.is_active,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


@router.get("/bindings", response_model=list[CGMBindingOut])
def list_bindings(
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        select(CGMDeviceBinding)
        .where(CGMDeviceBinding.user_id == user_id)
        .order_by(CGMDeviceBinding.created_at.desc())
    ).scalars().all()
    return [_to_binding_out(r) for r in rows]


@router.post("/bindings", response_model=CGMBindingOut, status_code=status.HTTP_201_CREATED)
def create_binding(
    payload: CGMBindingCreate,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    row = CGMDeviceBinding(
        user_id=user_id,
        provider=payload.provider,
        phone=payload.phone,
        device_sn=payload.device_sn,
        device_id=payload.device_id,
        is_active=payload.is_active,
    )
    db.add(row)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail={
                "error_code": "BINDING_CONFLICT",
                "message": "provider + phone/device_sn/device_id already exists",
            },
        ) from exc
    db.refresh(row)
    return _to_binding_out(row)


@router.delete("/bindings/{binding_id}")
def delete_binding(
    binding_id: int,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    row = db.execute(
        select(CGMDeviceBinding).where(
            CGMDeviceBinding.id == binding_id,
            CGMDeviceBinding.user_id == user_id,
        )
    ).scalars().first()
    if row is None:
        raise HTTPException(status_code=404, detail="Binding not found")
    db.delete(row)
    db.commit()
    return {"ok": True}


@router.post("/ingest", response_model=CGMIngestResponse)
async def ingest_cgm_webhook(
    request: Request,
    x_cgm_timestamp: str | None = Header(default=None),
    x_cgm_signature: str | None = Header(default=None),
    x_cgm_provider: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    raw_body = await request.body()
    verified = verify_signature(
        raw_body=raw_body,
        secret=settings.CGM_SHARED_SECRET,
        timestamp=x_cgm_timestamp,
        signature=x_cgm_signature,
        allow_unsigned=settings.CGM_ALLOW_UNSIGNED,
    )
    if not verified:
        raise HTTPException(
            status_code=403,
            detail={"error_code": "BAD_SIGNATURE", "message": "CGM signature verification failed"},
        )

    try:
        raw_json = json.loads(raw_body.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=400,
            detail={"error_code": "BAD_JSON", "message": str(exc)},
        ) from exc

    try:
        patients = parse_cgm_payload(raw_json)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=400,
            detail={"error_code": "BAD_PAYLOAD", "message": str(exc)},
        ) from exc

    provider = (x_cgm_provider or settings.CGM_PROVIDER_NAME).strip()
    result = ingest_cgm_records(
        db,
        provider=provider,
        source_name=settings.CGM_SOURCE_NAME,
        device_timezone=settings.CGM_DEVICE_TIMEZONE,
        patients=patients,
    )
    return CGMIngestResponse(**result)
