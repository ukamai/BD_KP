from datetime import date

from sqlalchemy import BigInteger, Date, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class InventoryTransaction(Base):
    __tablename__ = "inventory_transactions"

    inv_tx_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    project_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    material_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    task_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    po_item_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    transaction_type: Mapped[str] = mapped_column(String(20), nullable=False)
    quantity: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    transaction_date: Mapped[date] = mapped_column(Date, nullable=False)
    comment: Mapped[str | None] = mapped_column(String, nullable=True)
