from sqlalchemy import BigInteger, Date, Numeric, String, TIMESTAMP
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"

    po_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    project_id: Mapped[int] = mapped_column(BigInteger)
    supplier_id: Mapped[int] = mapped_column(BigInteger)

    po_number: Mapped[str] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(20))

    total_amount: Mapped[float] = mapped_column(Numeric(12, 2))
    order_date: Mapped[str] = mapped_column(Date)
    expected_delivery_date: Mapped[str | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[str] = mapped_column(TIMESTAMP)


class PurchaseOrderItem(Base):
    __tablename__ = "purchase_order_items"

    po_item_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    po_id: Mapped[int] = mapped_column(BigInteger)
    material_id: Mapped[int] = mapped_column(BigInteger)

    quantity_ordered: Mapped[float] = mapped_column(Numeric(10, 2))
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2))
    delivered_quantity: Mapped[float] = mapped_column(Numeric(10, 2))
    line_total: Mapped[float] = mapped_column(Numeric(12, 2))
