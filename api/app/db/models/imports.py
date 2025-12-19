from sqlalchemy import BigInteger, Boolean, Integer, Text, TIMESTAMP
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import text

from app.db.base import Base


class ImportError(Base):
    __tablename__ = "import_errors"

    error_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    occurred_at: Mapped[object] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
    run_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    source: Mapped[str] = mapped_column(Text, nullable=False)
    payload: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    error_message: Mapped[str] = mapped_column(Text, nullable=False)
    user_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    details: Mapped[dict | None] = mapped_column(JSONB, nullable=True)


class ImportRun(Base):
    __tablename__ = "import_runs"

    run_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    started_at: Mapped[object] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
    finished_at: Mapped[object | None] = mapped_column(TIMESTAMP, nullable=True)
    source: Mapped[str] = mapped_column(Text, nullable=False)
    entity: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'inventory_transactions'"))
    total_rows: Mapped[int] = mapped_column(Integer, nullable=False)
    inserted_rows: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    failed_rows: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    fail_fast: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'running'"))
    user_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    meta: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
