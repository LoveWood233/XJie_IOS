from fastapi import Depends, Header, HTTPException

from app.core.security import decode_token
from app.core.token_blacklist import get_blacklist
from app.db.session import SessionLocal


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user_id(authorization: str = Header(default="")) -> int:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = decode_token(token)
        # Reject blacklisted tokens (logged-out)
        jti = payload.get("jti")
        if jti and get_blacklist().is_blacklisted(jti):
            raise HTTPException(status_code=401, detail="Token revoked")
        return int(payload["sub"])
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=401, detail="Invalid token") from exc


def require_admin(
    user_id: int = Depends(get_current_user_id),
    db=Depends(get_db),
) -> int:
    """Return user_id only if the user has is_admin=True."""
    from app.models.user import User

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    return user_id
