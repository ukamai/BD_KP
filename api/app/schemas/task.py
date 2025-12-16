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


class TaskUpdate(BaseModel):
    status: str | None = Field(default=None, max_length=20)
    actual_cost: float | None = Field(default=None, ge=0)
    actual_start_date: date | None = None
    actual_end_date: date | None = None
