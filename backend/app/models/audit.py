
from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.compat import JSONB

from app.db.base import Base


class LLMAuditLog(Base):
    __tablename__ = "llm_audit_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("user_account.id"), index=True, nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    provider: Mapped[str] = mapped_column(String, nullable=False)
    model: Mapped[str] = mapped_column(String, nullable=False)
    feature: Mapped[str] = mapped_column(String, nullable=False, default="chat", server_default="chat")
    latency_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    prompt_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)
    completion_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)

    context_hash: Mapped[str] = mapped_column(String, nullable=False)
    meta: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
