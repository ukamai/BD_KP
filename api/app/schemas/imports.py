from datetime import date

from pydantic import BaseModel, Field


class InventoryTransactionImportItem(BaseModel):
    project_id: int
    material_id: int
    task_id: int | None = None
    po_item_id: int | None = None
    transaction_type: str = Field(min_length=1, max_length=20)
    quantity: float
    unit_price: float
    transaction_date: date
    comment: str | None = None


class BatchImportRequest(BaseModel):
    items: list[InventoryTransactionImportItem] = Field(min_length=1)
    source: str | None = Field(default="api", max_length=50)
    fail_fast: bool = False


class BatchImportResponse(BaseModel):
    run_id: int | None = None
    inserted: int | None = None
    failed: int | None = None


class BatchImportFakerRequest(BaseModel):
    count: int = Field(default=500, ge=1, le=50000)
    invalid_rate: float = Field(default=0.0, ge=0.0, le=1.0)
    fail_fast: bool = False
    source: str | None = Field(default="faker", max_length=50)

    seed: int | None = None

    project_id: int | None = None
    material_id: int | None = None
    task_id: int | None = None
    po_item_id: int | None = None

    allow_task_id: bool = True
    allow_po_item_id: bool = True

    transaction_types: list[str] | None = None

    date_from: date | None = None
    date_to: date | None = None
