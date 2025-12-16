from datetime import date
from pydantic import BaseModel, Field


class InvTxRow(BaseModel):
    project_id: int
    material_id: int
    task_id: int | None = None
    po_item_id: int | None = None
    transaction_type: str = Field(max_length=20)
    quantity: float = Field(gt=0)
    unit_price: float = Field(ge=0, default=0)
    transaction_date: date
    comment: str | None = None


class BatchImportRequest(BaseModel):
    source: str = Field(default="api_batch_import")
    fail_fast: bool = False
    rows: list[InvTxRow] = Field(min_length=1)


class BatchImportResult(BaseModel):
    ok: bool
    rows_received: int
    errors_before: int
    errors_after: int
    errors_added: int
