
from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.compat import JSONB

from app.db.base import Base


class GlucoseReading(Base):
    __tablename__ = "glucose_readings"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), index=True, nullable=False)
    ts: Mapped[DateTime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    glucose_mgdl: Mapped[int] = mapped_column(Integer, nullable=False)
    source: Mapped[str] = mapped_column(String, default="manual_import", nullable=False)
    meta: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)


Index("ix_glucose_user_ts", GlucoseReading.user_id, GlucoseReading.ts)
