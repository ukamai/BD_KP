from datetime import date, datetime

from sqlalchemy import BigInteger, Date, Numeric, String, TIMESTAMP, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Defect(Base):
    __tablename__ = "defects"

    defect_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    task_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    contractor_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    description: Mapped[str] = mapped_column(String, nullable=False)
    severity: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    defect_date: Mapped[date] = mapped_column(Date, nullable=False)
    resolution_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    rework_cost: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, server_default=text("0"))


class AcceptanceAct(Base):
    __tablename__ = "acceptance_acts"

    task_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    acceptance_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    accepted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    result_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    comment: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
