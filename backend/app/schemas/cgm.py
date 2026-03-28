from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field, field_validator, model_validator


class CGMRecordIn(BaseModel):
    deviceTime: str
    eventData: float | int | str
    timeOffset: int | str | None = None


class CGMPatientDataIn(BaseModel):
    phone: str | None = None
    name: str | None = None
    deviceSn: str | None = None
    deviceId: str | None = None
    recordList: list[CGMRecordIn] = Field(default_factory=list)

    @field_validator("phone", "name", "deviceSn", "deviceId")
    @classmethod
    def _normalize_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        v = value.strip()
        return v or None

    @model_validator(mode="after")
    def _check_identifier(self) -> "CGMPatientDataIn":
        if not self.phone and not self.deviceSn and not self.deviceId:
            raise ValueError("At least one of phone/deviceSn/deviceId is required")
        return self


class CGMIngestResponse(BaseModel):
    provider: str
    received_patients: int
    inserted_points: int
    skipped_points: int
    unknown_bindings: int
    errors: list[dict] = Field(default_factory=list)


class CGMBindingCreate(BaseModel):
    provider: str = Field(default="vendor_cgm", min_length=1, max_length=32)
    phone: str | None = Field(default=None, max_length=32)
    device_sn: str | None = Field(default=None, max_length=64)
    device_id: str | None = Field(default=None, max_length=128)
    is_active: bool = True

    @field_validator("phone")
    @classmethod
    def _normalize_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        v = value.strip()
        return v or None

    @field_validator("provider")
    @classmethod
    def _normalize_provider(cls, value: str) -> str:
        v = value.strip()
        if not v:
            raise ValueError("provider is required")
        return v

    @field_validator("device_sn", "device_id")
    @classmethod
    def _normalize_device(cls, value: str | None) -> str | None:
        if value is None:
            return None
        v = value.strip()
        return v or None

    @model_validator(mode="after")
    def _check_at_least_one(self) -> "CGMBindingCreate":
        if not self.phone and not self.device_sn and not self.device_id:
            raise ValueError("At least one of phone/device_sn/device_id is required")
        return self


class CGMBindingOut(BaseModel):
    id: str
    provider: str
    phone: str | None
    device_sn: str | None
    device_id: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
