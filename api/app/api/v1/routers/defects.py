from fastapi import APIRouter, Depends, HTTPException
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
    return db.execute(stmt.order_by(Defect.defect_id)).scalars().all()


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
