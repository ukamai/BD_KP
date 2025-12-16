from datetime import date
from pydantic import BaseModel, Field


class PurchaseOrderItemCreate(BaseModel):
    material_id: int
    quantity_ordered: float = Field(gt=0)
    unit_price: float = Field(ge=0)


class PurchaseOrderCreate(BaseModel):
    project_id: int
    supplier_id: int
    order_date: date
    expected_delivery_date: date | None = None
    status: str = Field(default="ordered", max_length=20)
    items: list[PurchaseOrderItemCreate] = Field(min_length=1)


class PurchaseOrderOut(BaseModel):
    po_id: int
    project_id: int
    supplier_id: int
    po_number: str
    status: str
    total_amount: float
    order_date: date
    expected_delivery_date: date | None

    class Config:
        from_attributes = True
