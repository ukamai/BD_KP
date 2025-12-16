from sqlalchemy import BigInteger, JSON, String, TIMESTAMP
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ImportError(Base):
    __tablename__ = "import_errors"

    error_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    occurred_at: Mapped[str] = mapped_column(TIMESTAMP)
    source: Mapped[str] = mapped_column(String)
    payload: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    error_message: Mapped[str] = mapped_column(String)
    user_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
