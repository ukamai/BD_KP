from sqlalchemy import BigInteger, Date, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ProjectTask(Base):
    __tablename__ = "project_tasks"

    task_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    project_id: Mapped[int] = mapped_column(BigInteger)
    phase_id: Mapped[int] = mapped_column(BigInteger)

    room_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    work_type_id: Mapped[int] = mapped_column(BigInteger)
    contractor_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    task_name: Mapped[str] = mapped_column(String(200))

    volume: Mapped[float] = mapped_column(Numeric(10, 2))
    planned_cost: Mapped[float] = mapped_column(Numeric(10, 2))
    actual_cost: Mapped[float] = mapped_column(Numeric(10, 2))

    status: Mapped[str] = mapped_column(String(20))

    planned_start_date: Mapped[Date | None] = mapped_column(Date, nullable=True)
    planned_end_date: Mapped[Date | None] = mapped_column(Date, nullable=True)
    actual_start_date: Mapped[Date | None] = mapped_column(Date, nullable=True)
    actual_end_date: Mapped[Date | None] = mapped_column(Date, nullable=True)
