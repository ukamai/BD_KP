from datetime import date, datetime

from sqlalchemy import BigInteger, Date, Numeric, String, TIMESTAMP, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Project(Base):
    __tablename__ = "projects"

    project_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    property_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    contract_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    project_name: Mapped[str] = mapped_column(String(200), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)

    total_budget: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    actual_cost: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False, server_default=text("0"))

    planned_start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    planned_end_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
