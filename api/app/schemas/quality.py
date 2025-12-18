from datetime import date

from pydantic import BaseModel, Field


class DefectOut(BaseModel):
    defect_id: int
    task_id: int
    contractor_id: int | None
    description: str
    severity: str
    status: str
    defect_date: date
    resolution_date: date | None
    rework_cost: float

    class Config:
        from_attributes = True


class DefectCreate(BaseModel):
    task_id: int
    contractor_id: int | None = None
    description: str = Field(min_length=1)
    severity: str = Field(min_length=1, max_length=20)
    status: str = Field(default="open", max_length=20)
    defect_date: date
    resolution_date: date | None = None
    rework_cost: float = Field(default=0, ge=0)


class DefectUpdate(BaseModel):
    task_id: int | None = None
    contractor_id: int | None = None
    description: str | None = Field(default=None, min_length=1)
    severity: str | None = Field(default=None, min_length=1, max_length=20)
    status: str | None = Field(default=None, max_length=20)
    defect_date: date | None = None
    resolution_date: date | None = None
    rework_cost: float | None = Field(default=None, ge=0)


class AcceptanceActOut(BaseModel):
    task_id: int
    acceptance_date: date | None
    accepted_by: str | None
    result_status: str | None
    comment: str | None

    class Config:
        from_attributes = True


class AcceptanceActCreate(BaseModel):
    task_id: int
    acceptance_date: date | None = None
    accepted_by: str | None = Field(default=None, max_length=100)
    result_status: str | None = Field(default=None, max_length=20)
    comment: str | None = None


class AcceptanceActUpdate(BaseModel):
    acceptance_date: date | None = None
    accepted_by: str | None = Field(default=None, max_length=100)
    result_status: str | None = Field(default=None, max_length=20)
    comment: str | None = None
