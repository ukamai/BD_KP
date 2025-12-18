from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.quality import AcceptanceAct
from app.db.session import get_db
from app.schemas.quality import AcceptanceActCreate, AcceptanceActOut, AcceptanceActUpdate

router = APIRouter()


@router.get("", response_model=list[AcceptanceActOut])
def list_acceptance_acts(project_id: int | None = None, task_id: int | None = None, db: Session = Depends(get_db)):
    stmt = select(AcceptanceAct)
    if project_id is not None:
        from app.db.models.task import ProjectTask

        stmt = stmt.join(ProjectTask, ProjectTask.task_id == AcceptanceAct.task_id).where(
            ProjectTask.project_id == project_id
        )
    if task_id is not None:
        stmt = stmt.where(AcceptanceAct.task_id == task_id)
    return db.execute(stmt.order_by(AcceptanceAct.task_id)).scalars().all()


@router.get("/{task_id}", response_model=AcceptanceActOut)
def get_acceptance_act(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(AcceptanceAct, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Acceptance act not found")
    return obj


@router.post("", response_model=AcceptanceActOut, status_code=201)
def create_acceptance_act(payload: AcceptanceActCreate, db: Session = Depends(get_db)):
    obj = AcceptanceAct(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{task_id}", response_model=AcceptanceActOut)
def update_acceptance_act(task_id: int, payload: AcceptanceActUpdate, db: Session = Depends(get_db)):
    obj = db.get(AcceptanceAct, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Acceptance act not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{task_id}", status_code=204)
def delete_acceptance_act(task_id: int, db: Session = Depends(get_db)):
    obj = db.get(AcceptanceAct, task_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Acceptance act not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
