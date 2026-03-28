"""Token blacklist for logout / refresh invalidation.

Uses Redis when available, falls back to an in-memory set for local dev.
"""
from __future__ import annotations

import logging
import time
from typing import Protocol

logger = logging.getLogger(__name__)

# ── In-memory fallback ──────────────────────────────────────


class _MemoryBlacklist:
    """Simple expiring-set for local development (not shared across workers)."""

    def __init__(self) -> None:
        self._store: dict[str, float] = {}  # jti -> expire_ts

    def add(self, jti: str, expires_at: float) -> None:
        self._store[jti] = expires_at

    def is_blacklisted(self, jti: str) -> bool:
        exp = self._store.get(jti)
        if exp is None:
            return False
        if time.time() > exp:
            del self._store[jti]
            return False
        return True

    def cleanup(self) -> None:
        now = time.time()
        self._store = {k: v for k, v in self._store.items() if v > now}


# ── Redis-backed blacklist ──────────────────────────────────


class _RedisBlacklist:
    def __init__(self, redis_client) -> None:  # type: ignore[no-untyped-def]
        self._r = redis_client

    def add(self, jti: str, expires_at: float) -> None:
        ttl = max(int(expires_at - time.time()), 1)
        self._r.setex(f"bl:{jti}", ttl, "1")

    def is_blacklisted(self, jti: str) -> bool:
        return bool(self._r.exists(f"bl:{jti}"))


# ── Factory ─────────────────────────────────────────────────

_instance: _MemoryBlacklist | _RedisBlacklist | None = None


def get_blacklist() -> _MemoryBlacklist | _RedisBlacklist:
    global _instance
    if _instance is not None:
        return _instance

    try:
        import redis as _redis  # noqa: PLC0415

        from app.core.config import settings

        r = _redis.from_url(settings.REDIS_URL, decode_responses=True, socket_connect_timeout=2)
        r.ping()
        _instance = _RedisBlacklist(r)
        logger.info("Token blacklist: using Redis")
    except Exception:  # noqa: BLE001
        _instance = _MemoryBlacklist()
        logger.info("Token blacklist: using in-memory fallback")

    return _instance
