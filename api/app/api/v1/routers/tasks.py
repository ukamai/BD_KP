from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError, DataError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.task import ProjectTask
from app.schemas.task import TaskOut, TaskCreate, TaskUpdate, TaskBulkStatusUpdate, TaskBulkResult

router = APIRouter()


@router.get("/tasks", response_model=list[TaskOut])
def list_tasks(
    project_id: int | None = None,
    phase_id: int | None = None,
    room_id: int | None = None,
    work_type_id: int | None = None,
    contractor_id: int | None = None,
    status: str | None = None,
    q: str | None = None,
    sort_by: str = Query(default="task_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(ProjectTask)
    if project_id is not None:
        stmt = stmt.where(ProjectTask.project_id == project_id)
    if phase_id is not None:
        stmt = stmt.where(ProjectTask.phase_id == phase_id)
    if room_id is not None:
        stmt = stmt.where(ProjectTask.room_id == room_id)
    if work_type_id is not None:
        stmt = stmt.where(ProjectTask.work_type_id == work_type_id)
    if contractor_id is not None:
        stmt = stmt.where(ProjectTask.contractor_id == contractor_id)
    if status is not None:
        stmt = stmt.where(ProjectTask.status == status)
    if q:
        stmt = stmt.where(ProjectTask.task_name.ilike(f"%{q}%"))

    sort_map = {
        "task_id": ProjectTask.task_id,
        "project_id": ProjectTask.project_id,
        "phase_id": ProjectTask.phase_id,
        "room_id": ProjectTask.room_id,
        "work_type_id": ProjectTask.work_type_id,
        "contractor_id": ProjectTask.contractor_id,
        "status": ProjectTask.status,
        "planned_cost": ProjectTask.planned_cost,
        "actual_cost": ProjectTask.actual_cost,
        "planned_start_date": ProjectTask.planned_start_date,
        "planned_end_date": ProjectTask.planned_end_date,
        "actual_start_date": ProjectTask.actual_start_date,
        "actual_end_date": ProjectTask.actual_end_date,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    stmt = stmt.order_by(col).limit(limit).offset(offset)
    return db.execute(stmt).scalars().all()


@router.patch("/tasks/batch/status", response_model=TaskBulkResult)
def bulk_update_task_status(payload: TaskBulkStatusUpdate, db: Session = Depends(get_db)):
    if not payload.task_ids:
        raise HTTPException(status_code=400, detail="task_ids is empty")

    stmt = (
        update(ProjectTask)
        .where(ProjectTask.task_id.in_(payload.task_ids))
        .values(status=payload.status)
        .returning(ProjectTask.task_id)
    )

    try:
        rows = db.execute(stmt).all()
        db.commit()
        updated_ids = [int(r[0]) for r in rows]
        return TaskBulkResult(updated=len(updated_ids), task_ids=updated_ids)
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(ProjectTask, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Task not found")
    return obj


@router.post("/tasks", response_model=TaskOut, status_code=201)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    obj = ProjectTask(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: int, payload: TaskUpdate, db: Session = Depends(get_db)):
    obj = db.get(ProjectTask, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Task not found")

    data = payload.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(ProjectTask, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
