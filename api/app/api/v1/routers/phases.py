from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.planning import ProjectPhase
from app.db.session import get_db
from app.schemas.planning import PhaseCreate, PhaseOut, PhaseUpdate

router = APIRouter()


@router.get("", response_model=list[PhaseOut])
def list_phases(project_id: int | None = None, db: Session = Depends(get_db)):
    stmt = select(ProjectPhase)
    if project_id is not None:
        stmt = stmt.where(ProjectPhase.project_id == project_id)
    return db.execute(stmt.order_by(ProjectPhase.phase_id)).scalars().all()


@router.get("/{phase_id}", response_model=PhaseOut)
def get_phase(phase_id: int, db: Session = Depends(get_db)):
    obj = db.get(ProjectPhase, phase_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Phase not found")
    return obj


@router.post("", response_model=PhaseOut, status_code=201)
def create_phase(payload: PhaseCreate, db: Session = Depends(get_db)):
    obj = ProjectPhase(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{phase_id}", response_model=PhaseOut)
def update_phase(phase_id: int, payload: PhaseUpdate, db: Session = Depends(get_db)):
    obj = db.get(ProjectPhase, phase_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Phase not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{phase_id}", status_code=204)
def delete_phase(phase_id: int, db: Session = Depends(get_db)):
    obj = db.get(ProjectPhase, phase_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Phase not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
