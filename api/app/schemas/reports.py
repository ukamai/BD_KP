from datetime import date
from pydantic import BaseModel


class ProjectReportRow(BaseModel):
    project_id: int
    project_name: str
    status: str
    planned_start: date | None
    planned_end: date | None
    total_budget: float

    tasks_total: int
    tasks_completed: int
    pct_completed: float

    tasks_actual_sum: float
    materials_out_sum: float
    defects_cnt: int
    rework_sum: float

    total_spent: float
    budget_delta: float
