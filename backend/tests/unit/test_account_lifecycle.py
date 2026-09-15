from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models.activity_log import ActivityLog  # noqa: F401
from app.models.consent import Consent  # noqa: F401
from app.models.glucose import GlucoseReading  # noqa: F401
from app.models.password_reset_code import PasswordResetCode  # noqa: F401
from app.models.user import User
from app.models.user_profile import UserProfile  # noqa: F401
from app.models.user_settings import UserSettings  # noqa: F401
from app.routers import auth, users
from app.schemas.user import LoginRequest, SignupRequest


def _db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


def _request():
    return SimpleNamespace(
        client=SimpleNamespace(host="127.0.0.1"),
        headers={"user-agent": "unit-test"},
    )


def test_account_lifecycle_delete_and_reregister_same_phone(monkeypatch, caplog):
    auth._login_attempts.clear()
    monkeypatch.setattr(
        auth.settings,
        "JWT_SECRET",
        "unit-test-signing-secret-at-least-32-bytes",
    )
    db = _db_session()

    with caplog.at_level("INFO"):
        first_auth = auth.signup(
            SignupRequest(
                phone="199 8000 0001",
                username=" tester ",
                password="UnitTestPassword!42",
            ),
            request=_request(),
            db=db,
        )
    first_user = db.execute(select(User).where(User.phone == "19980000001")).scalars().one()

    me = users.me(user_id=first_user.id, db=db)
    assert me.phone == "19980000001"
    assert me.username == "tester"
    assert me.settings is not None
    assert me.consent["allow_data_upload"] is True

    response = users.delete_me(
        user_id=first_user.id,
        authorization=f"Bearer {first_auth.access_token}",
        db=db,
    )
    assert response.status_code == 204

    deleted_user = db.get(User, first_user.id)
    assert deleted_user.deleted == 1
    assert deleted_user.phone == f"deleted_{first_user.id}"[:20]

    with pytest.raises(HTTPException) as login_error:
        auth.login(
            LoginRequest(phone="19980000001", password="UnitTestPassword!42"),
            request=_request(),
            db=db,
        )
    assert login_error.value.status_code == 401
    assert "19980000001" not in caplog.text

    second_auth = auth.signup(
        SignupRequest(phone="19980000001", username="tester2", password="UnitTestPassword!42"),
        request=_request(),
        db=db,
    )
    assert second_auth.access_token

    active_users = db.execute(
        select(User).where(User.phone == "19980000001", User.deleted == 0)
    ).scalars().all()
    assert len(active_users) == 1
    assert active_users[0].id != first_user.id


def test_production_password_reset_fails_closed_without_logging_or_storing_code(
    monkeypatch,
    caplog,
):
    db = _db_session()
    db.add(User(phone="19980000002", username="reset-user", password="x"))
    db.commit()
    auth._reset_request_window.clear()
    monkeypatch.setattr(auth.settings, "APP_ENV", "production")
    monkeypatch.setattr(auth.settings, "ALLOW_INSECURE_DEVELOPMENT", False)

    with caplog.at_level("INFO"), pytest.raises(HTTPException) as error:
        auth.password_reset_request(
            auth.PasswordResetRequestIn(phone="19980000002"),
            db=db,
        )

    assert error.value.status_code == 503
    assert db.scalar(select(PasswordResetCode)) is None
    assert "19980000002" not in caplog.text
    assert "DEV-CODE" not in caplog.text
