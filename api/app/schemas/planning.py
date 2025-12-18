from datetime import date

from pydantic import BaseModel, Field


class PhaseOut(BaseModel):
    phase_id: int
    project_id: int
    phase_name: str
    phase_order: int
    status: str
    planned_start_date: date | None
    planned_end_date: date | None

    class Config:
        from_attributes = True


class PhaseCreate(BaseModel):
    project_id: int
    phase_name: str = Field(min_length=1, max_length=100)
    phase_order: int = Field(gt=0)
    status: str = Field(default="planned", max_length=20)
    planned_start_date: date | None = None
    planned_end_date: date | None = None


class PhaseUpdate(BaseModel):
    project_id: int | None = None
    phase_name: str | None = Field(default=None, min_length=1, max_length=100)
    phase_order: int | None = Field(default=None, gt=0)
    status: str | None = Field(default=None, max_length=20)
    planned_start_date: date | None = None
    planned_end_date: date | None = None


class WorkTypeOut(BaseModel):
    work_type_id: int
    work_type_name: str
    category: str | None
    default_unit: str
    standard_rate: float
    is_active: bool
    description: str | None

    class Config:
        from_attributes = True


class WorkTypeCreate(BaseModel):
    work_type_name: str = Field(min_length=1, max_length=100)
    category: str | None = Field(default=None, max_length=50)
    default_unit: str = Field(min_length=1, max_length=20)
    standard_rate: float = Field(default=0, ge=0)
    is_active: bool = True
    description: str | None = None


class WorkTypeUpdate(BaseModel):
    work_type_name: str | None = Field(default=None, min_length=1, max_length=100)
    category: str | None = Field(default=None, max_length=50)
    default_unit: str | None = Field(default=None, min_length=1, max_length=20)
    standard_rate: float | None = Field(default=None, ge=0)
    is_active: bool | None = None
    description: str | None = None
