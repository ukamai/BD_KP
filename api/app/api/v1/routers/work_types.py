from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.planning import WorkType
from app.db.session import get_db
from app.schemas.planning import WorkTypeCreate, WorkTypeOut, WorkTypeUpdate

router = APIRouter()


@router.get("", response_model=list[WorkTypeOut])
def list_work_types(db: Session = Depends(get_db)):
    return db.execute(select(WorkType).order_by(WorkType.work_type_id)).scalars().all()


@router.get("/{work_type_id}", response_model=WorkTypeOut)
def get_work_type(work_type_id: int, db: Session = Depends(get_db)):
    obj = db.get(WorkType, work_type_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Work type not found")
    return obj


@router.post("", response_model=WorkTypeOut, status_code=201)
def create_work_type(payload: WorkTypeCreate, db: Session = Depends(get_db)):
    obj = WorkType(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{work_type_id}", response_model=WorkTypeOut)
def update_work_type(work_type_id: int, payload: WorkTypeUpdate, db: Session = Depends(get_db)):
    obj = db.get(WorkType, work_type_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Work type not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{work_type_id}", status_code=204)
def delete_work_type(work_type_id: int, db: Session = Depends(get_db)):
    obj = db.get(WorkType, work_type_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Work type not found")

    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
