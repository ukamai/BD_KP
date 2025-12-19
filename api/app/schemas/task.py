from datetime import date
from pydantic import BaseModel, Field


class TaskOut(BaseModel):
    task_id: int
    project_id: int
    phase_id: int
    room_id: int | None
    work_type_id: int
    contractor_id: int | None
    task_name: str
    volume: float
    planned_cost: float
    actual_cost: float
    status: str
    planned_start_date: date | None
    planned_end_date: date | None
    actual_start_date: date | None
    actual_end_date: date | None

    class Config:
        from_attributes = True


class TaskCreate(BaseModel):
    project_id: int
    phase_id: int
    room_id: int | None = None
    work_type_id: int
    contractor_id: int | None = None

    task_name: str = Field(min_length=1, max_length=200)
    volume: float = Field(default=0, ge=0)
    planned_cost: float = Field(default=0, ge=0)
    actual_cost: float = Field(default=0, ge=0)

    status: str = Field(default="planned", max_length=20)

    planned_start_date: date | None = None
    planned_end_date: date | None = None
    actual_start_date: date | None = None
    actual_end_date: date | None = None


class TaskUpdate(BaseModel):
    status: str | None = Field(default=None, max_length=20)
    actual_cost: float | None = Field(default=None, ge=0)
    actual_start_date: date | None = None
    actual_end_date: date | None = None


class TaskBulkStatusUpdate(BaseModel):
    task_ids: list[int] = Field(min_length=1)
    status: str = Field(min_length=1, max_length=20)


class TaskBulkResult(BaseModel):
    updated: int
    task_ids: list[int]
