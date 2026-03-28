
from sqlalchemy import DateTime, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column


from app.db.base import Base


class User(Base):
    __tablename__ = "user_account"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    username: Mapped[str] = mapped_column(String(50), nullable=False)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    sync_flag: Mapped[int | None] = mapped_column(SmallInteger, default=0)
    created_at: Mapped[DateTime | None] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[DateTime | None] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    deleted: Mapped[int | None] = mapped_column(SmallInteger, default=0)
