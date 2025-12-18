from datetime import date, datetime

from sqlalchemy import BigInteger, Date, Numeric, String, TIMESTAMP, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Contractor(Base):
    __tablename__ = "contractors"

    contractor_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    inn: Mapped[str] = mapped_column(String(12), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    email: Mapped[str | None] = mapped_column(String(100), nullable=True)
    specialization: Mapped[str | None] = mapped_column(String(100), nullable=True)
    rating: Mapped[float | None] = mapped_column(Numeric(3, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))


class Contract(Base):
    __tablename__ = "contracts"

    contract_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    property_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    contractor_id: Mapped[int] = mapped_column(BigInteger, nullable=False)

    contract_number: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)

    total_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    signed_at: Mapped[date | None] = mapped_column(Date, nullable=True)
