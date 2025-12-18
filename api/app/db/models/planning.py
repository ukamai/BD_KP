from datetime import date

from sqlalchemy import BigInteger, Boolean, Date, Integer, Numeric, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ProjectPhase(Base):
    __tablename__ = "project_phases"

    phase_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    project_id: Mapped[int] = mapped_column(BigInteger, nullable=False)

    phase_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phase_order: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)

    planned_start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    planned_end_date: Mapped[date | None] = mapped_column(Date, nullable=True)


class WorkType(Base):
    __tablename__ = "work_types"

    work_type_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    work_type_name: Mapped[str] = mapped_column(String(100), nullable=False)
    category: Mapped[str | None] = mapped_column(String(50), nullable=True)
    default_unit: Mapped[str] = mapped_column(String(20), nullable=False)
    standard_rate: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, server_default=text("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    description: Mapped[str | None] = mapped_column(String, nullable=True)
