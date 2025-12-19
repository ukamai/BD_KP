from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.quality import Defect
from app.db.session import get_db
from app.schemas.quality import DefectCreate, DefectOut, DefectUpdate

router = APIRouter()


@router.get("", response_model=list[DefectOut])
def list_defects(
    project_id: int | None = None,
    task_id: int | None = None,
    room_id: int | None = None,
    contractor_id: int | None = None,
    status: str | None = None,
    severity: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    sort_by: str = Query(default="defect_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Defect)
    if project_id is not None or room_id is not None:
        from app.db.models.task import ProjectTask

        stmt = stmt.join(ProjectTask, ProjectTask.task_id == Defect.task_id)
        if project_id is not None:
            stmt = stmt.where(ProjectTask.project_id == project_id)
        if room_id is not None:
            stmt = stmt.where(ProjectTask.room_id == room_id)
    if task_id is not None:
        stmt = stmt.where(Defect.task_id == task_id)
    if contractor_id is not None:
        stmt = stmt.where(Defect.contractor_id == contractor_id)
    if status is not None:
        stmt = stmt.where(Defect.status == status)
    if severity is not None:
        stmt = stmt.where(Defect.severity == severity)
    if date_from is not None:
        stmt = stmt.where(Defect.defect_date >= date_from)
    if date_to is not None:
        stmt = stmt.where(Defect.defect_date <= date_to)

    sort_map = {
        "defect_id": Defect.defect_id,
        "task_id": Defect.task_id,
        "contractor_id": Defect.contractor_id,
        "severity": Defect.severity,
        "status": Defect.status,
        "defect_date": Defect.defect_date,
        "resolution_date": Defect.resolution_date,
        "rework_cost": Defect.rework_cost,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    return db.execute(stmt.order_by(col).limit(limit).offset(offset)).scalars().all()


@router.get("/{defect_id}", response_model=DefectOut)
def get_defect(defect_id: int, db: Session = Depends(get_db)):
    obj = db.get(Defect, defect_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Defect not found")
    return obj


@router.post("", response_model=DefectOut, status_code=201)
def create_defect(payload: DefectCreate, db: Session = Depends(get_db)):
    obj = Defect(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{defect_id}", response_model=DefectOut)
def update_defect(defect_id: int, payload: DefectUpdate, db: Session = Depends(get_db)):
    obj = db.get(Defect, defect_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Defect not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{defect_id}", status_code=204)
def delete_defect(defect_id: int, db: Session = Depends(get_db)):
    obj = db.get(Defect, defect_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Defect not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
