from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, DataError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.project import Project
from app.schemas.project import ProjectOut, ProjectCreate, ProjectUpdate

router = APIRouter()


@router.get("", response_model=list[ProjectOut])
def list_projects(
    property_id: int | None = None,
    contract_id: int | None = None,
    status: str | None = None,
    q: str | None = None,
    start_from: date | None = None,
    start_to: date | None = None,
    sort_by: str = Query(default="project_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Project)
    if property_id is not None:
        stmt = stmt.where(Project.property_id == property_id)
    if contract_id is not None:
        stmt = stmt.where(Project.contract_id == contract_id)
    if status is not None:
        stmt = stmt.where(Project.status == status)
    if q:
        stmt = stmt.where(Project.project_name.ilike(f"%{q}%"))
    if start_from is not None:
        stmt = stmt.where(Project.planned_start_date >= start_from)
    if start_to is not None:
        stmt = stmt.where(Project.planned_start_date <= start_to)

    sort_map = {
        "project_id": Project.project_id,
        "property_id": Project.property_id,
        "contract_id": Project.contract_id,
        "status": Project.status,
        "total_budget": Project.total_budget,
        "actual_cost": Project.actual_cost,
        "planned_start_date": Project.planned_start_date,
        "planned_end_date": Project.planned_end_date,
        "created_at": Project.created_at,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    return db.execute(stmt.order_by(col).limit(limit).offset(offset)).scalars().all()


@router.get("/{project_id}", response_model=ProjectOut)
def get_project(project_id: int, db: Session = Depends(get_db)):
    obj = db.get(Project, project_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Project not found")
    return obj


@router.post("", response_model=ProjectOut, status_code=201)
def create_project(payload: ProjectCreate, db: Session = Depends(get_db)):
    obj = Project(
        property_id=payload.property_id,
        contract_id=payload.contract_id,
        project_name=payload.project_name,
        status=payload.status,
        total_budget=payload.total_budget,
        actual_cost=0,
        planned_start_date=payload.planned_start_date,
        planned_end_date=payload.planned_end_date,
    )

    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.patch("/{project_id}", response_model=ProjectOut)
def update_project(project_id: int, payload: ProjectUpdate, db: Session = Depends(get_db)):
    obj = db.get(Project, project_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Project not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.delete("/{project_id}", status_code=204)
def delete_project(project_id: int, db: Session = Depends(get_db)):
    obj = db.get(Project, project_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Project not found")

    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")


@router.get("/{project_id}/tasks")
def list_project_tasks(
    project_id: int,
    status: str | None = None,
    sort_by: str = Query(default="task_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    from app.db.models.task import ProjectTask

    stmt = select(ProjectTask).where(ProjectTask.project_id == project_id)
    if status is not None:
        stmt = stmt.where(ProjectTask.status == status)

    sort_map = {
        "task_id": ProjectTask.task_id,
        "status": ProjectTask.status,
        "planned_cost": ProjectTask.planned_cost,
        "actual_cost": ProjectTask.actual_cost,
        "planned_start_date": ProjectTask.planned_start_date,
        "planned_end_date": ProjectTask.planned_end_date,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    return db.execute(stmt.order_by(col).limit(limit).offset(offset)).scalars().all()


@router.get("/{project_id}/phases")
def list_project_phases(project_id: int, db: Session = Depends(get_db)):
    from app.db.models.planning import ProjectPhase

    return db.execute(
        select(ProjectPhase).where(ProjectPhase.project_id == project_id).order_by(ProjectPhase.phase_id)
    ).scalars().all()
