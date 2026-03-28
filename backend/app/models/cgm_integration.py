from __future__ import annotations


from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Index, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class CGMDeviceBinding(Base):
    __tablename__ = "cgm_device_bindings"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), nullable=False)
    provider: Mapped[str] = mapped_column(String(32), nullable=False, default="vendor_cgm")

    # At least one of the three identifiers should be provided.
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    device_sn: Mapped[str | None] = mapped_column(String(64), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    __table_args__ = (
        Index("ix_cgm_bindings_user_provider", "user_id", "provider"),
        Index("ix_cgm_bindings_provider_phone", "provider", "phone"),
        Index("ix_cgm_bindings_provider_sn", "provider", "device_sn"),
        Index("ix_cgm_bindings_provider_id", "provider", "device_id"),
        UniqueConstraint("provider", "phone", name="uq_cgm_bindings_provider_phone"),
        UniqueConstraint("provider", "device_sn", name="uq_cgm_bindings_provider_sn"),
        UniqueConstraint("provider", "device_id", name="uq_cgm_bindings_provider_id"),
    )
