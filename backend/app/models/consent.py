
from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column


from app.db.base import Base


class Consent(Base):
    __tablename__ = "consents"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), index=True, nullable=False)

    allow_ai_chat: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    allow_data_upload: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    version: Mapped[str] = mapped_column(String, default="v1", nullable=False)
