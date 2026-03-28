from __future__ import annotations

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

from app.db.base import Base
from app.models.cgm_integration import CGMDeviceBinding
from app.models.glucose import GlucoseReading
from app.models.user import User
from app.schemas.cgm import CGMPatientDataIn
from app.services.cgm_service import ingest_cgm_records, parse_cgm_payload, verify_signature


def _make_db() -> Session:
    engine = create_engine("sqlite+pysqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    return sessionmaker(bind=engine, autoflush=False, autocommit=False)()


def test_parse_cgm_payload_supports_list_and_wrappers():
    payload1 = [{"phone": "13900001111", "recordList": [{"deviceTime": "2026-01-20 10:40:35", "eventData": 160}]}]
    payload2 = {"data": payload1}
    payload3 = {"patients": payload1}

    assert len(parse_cgm_payload(payload1)) == 1
    assert len(parse_cgm_payload(payload2)) == 1
    assert len(parse_cgm_payload(payload3)) == 1


def test_verify_signature_hmac_sha256():
    secret = "test_secret"
    raw_body = b'{"k":"v"}'
    ts = "1730000000"

    # Derived with the same algorithm once and fixed for regression.
    valid_sig = "cebfd29d38c84b22bd6b3f322416bd16e6eb15d47ce07d8e805d5190b3ec13b5"

    assert verify_signature(
        raw_body=raw_body,
        secret=secret,
        timestamp=ts,
        signature=valid_sig,
        allow_unsigned=False,
    )
    assert not verify_signature(
        raw_body=raw_body,
        secret=secret,
        timestamp=ts,
        signature="bad_signature",
        allow_unsigned=False,
    )


def test_ingest_cgm_records_inserts_and_deduplicates():
    db = _make_db()
    user = User(phone="13900001111", username="sc001", password="x")
    db.add(user)
    db.flush()
    db.add(
        CGMDeviceBinding(
            user_id=user.id,
            provider="vendor_cgm",
            phone="13900001111",
            device_sn="SN001",
            device_id="D001",
            is_active=True,
        )
    )
    db.commit()

    patients = [
        CGMPatientDataIn.model_validate(
            {
                "phone": "13900001111",
                "name": "tester",
                "deviceSn": "SN001",
                "deviceId": "D001",
                "recordList": [
                    {"deviceTime": "2026-01-20 10:40:35", "eventData": 160},
                    {"deviceTime": "2026-01-20 10:45:35", "eventData": 166},
                ],
            }
        )
    ]

    r1 = ingest_cgm_records(
        db,
        provider="vendor_cgm",
        source_name="cgm_device_api",
        device_timezone="Asia/Shanghai",
        patients=patients,
    )
    assert r1["inserted_points"] == 2
    assert r1["unknown_bindings"] == 0

    r2 = ingest_cgm_records(
        db,
        provider="vendor_cgm",
        source_name="cgm_device_api",
        device_timezone="Asia/Shanghai",
        patients=patients,
    )
    assert r2["inserted_points"] == 0
    assert r2["skipped_points"] == 2

    total = db.execute(select(GlucoseReading)).scalars().all()
    assert len(total) == 2
