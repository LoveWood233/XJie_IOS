from datetime import datetime

from pydantic import BaseModel, Field


class SignupRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=20)
    username: str = Field(min_length=1, max_length=50)
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=20)
    password: str = Field(min_length=8, max_length=128)


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    expires_in: int = 1800  # seconds


class RefreshRequest(BaseModel):
    refresh_token: str


class UserMeOut(BaseModel):
    id: str
    phone: str
    username: str | None = None
    created_at: datetime
    consent: dict
    settings: dict | None = None


class ConsentUpdateRequest(BaseModel):
    allow_ai_chat: bool | None = None
    allow_data_upload: bool | None = None


class ConsentOut(BaseModel):
    allow_ai_chat: bool
    allow_data_upload: bool
    version: str
    updated_at: datetime


# ── Subject-based login ──────────────────────────────────────


class SubjectInfo(BaseModel):
    subject_id: str
    cohort: str  # "cgm" | "liver"
    has_meals: bool
    has_glucose: bool
    display_name: str | None = None


class SubjectLoginRequest(BaseModel):
    subject_id: str = Field(min_length=2, max_length=30)


class WxLoginRequest(BaseModel):
    code: str = Field(min_length=1, max_length=256)
