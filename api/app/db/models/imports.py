from sqlalchemy import BigInteger, Text, TIMESTAMP
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import text

from app.db.base import Base


class ImportError(Base):
    __tablename__ = "import_errors"

    error_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    occurred_at: Mapped[object] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
    source: Mapped[str] = mapped_column(Text, nullable=False)
    payload: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    error_message: Mapped[str] = mapped_column(Text, nullable=False)
    user_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    details: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
