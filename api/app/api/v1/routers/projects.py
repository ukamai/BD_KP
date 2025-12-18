from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, DataError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.project import Project
from app.schemas.project import ProjectOut, ProjectCreate, ProjectUpdate

router = APIRouter()


@router.get("", response_model=list[ProjectOut])
def list_projects(db: Session = Depends(get_db)):
    return db.execute(select(Project).order_by(Project.project_id)).scalars().all()


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
def list_project_tasks(project_id: int, db: Session = Depends(get_db)):
    from app.db.models.task import ProjectTask

    return db.execute(
        select(ProjectTask).where(ProjectTask.project_id == project_id).order_by(ProjectTask.task_id)
    ).scalars().all()


@router.get("/{project_id}/phases")
def list_project_phases(project_id: int, db: Session = Depends(get_db)):
    from app.db.models.planning import ProjectPhase

    return db.execute(
        select(ProjectPhase).where(ProjectPhase.project_id == project_id).order_by(ProjectPhase.phase_id)
    ).scalars().all()
