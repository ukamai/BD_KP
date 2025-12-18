from datetime import date

from pydantic import BaseModel, Field


class InventoryTransactionOut(BaseModel):
    inv_tx_id: int
    project_id: int
    material_id: int
    task_id: int | None
    po_item_id: int | None
    transaction_type: str
    quantity: float
    unit_price: float
    transaction_date: date
    comment: str | None

    class Config:
        from_attributes = True


class InventoryTransactionCreate(BaseModel):
    project_id: int
    material_id: int
    task_id: int | None = None
    po_item_id: int | None = None
    transaction_type: str = Field(min_length=1, max_length=20)
    quantity: float = Field(gt=0)
    unit_price: float = Field(default=0, ge=0)
    transaction_date: date
    comment: str | None = None


class InventoryTransactionUpdate(BaseModel):
    project_id: int | None = None
    material_id: int | None = None
    task_id: int | None = None
    po_item_id: int | None = None
    transaction_type: str | None = Field(default=None, min_length=1, max_length=20)
    quantity: float | None = Field(default=None, gt=0)
    unit_price: float | None = Field(default=None, ge=0)
    transaction_date: date | None = None
    comment: str | None = None
