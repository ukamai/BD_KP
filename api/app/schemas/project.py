from datetime import date
from pydantic import BaseModel, Field


class ProjectOut(BaseModel):
    project_id: int
    property_id: int
    contract_id: int | None
    project_name: str
    status: str
    total_budget: float
    actual_cost: float
    planned_start_date: date | None
    planned_end_date: date | None

    class Config:
        from_attributes = True


class ProjectCreate(BaseModel):
    property_id: int
    contract_id: int | None = None
    project_name: str = Field(min_length=1, max_length=200)
    status: str = Field(default="active", max_length=20)
    total_budget: float = Field(ge=0)
    planned_start_date: date | None = None
    planned_end_date: date | None = None


class ProjectUpdate(BaseModel):
    project_name: str | None = Field(default=None, min_length=1, max_length=200)
    status: str | None = Field(default=None, max_length=20)
    total_budget: float | None = Field(default=None, ge=0)
    actual_cost: float | None = Field(default=None, ge=0)
    planned_start_date: date | None = None
    planned_end_date: date | None = None
