from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models.imports import ImportRun
from app.db.session import get_db
from app.schemas.imports import ImportRunOut

router = APIRouter()


@router.get("", response_model=list[ImportRunOut])
def list_import_runs(entity: str | None = None, source: str | None = None, limit: int = 200, db: Session = Depends(get_db)):
    stmt = select(ImportRun).order_by(ImportRun.run_id.desc()).limit(limit)
    if entity:
        stmt = stmt.where(ImportRun.entity == entity)
    if source:
        stmt = stmt.where(ImportRun.source == source)
    return db.execute(stmt).scalars().all()


@router.get("/{run_id}", response_model=ImportRunOut)
def get_import_run(run_id: int, db: Session = Depends(get_db)):
    obj = db.get(ImportRun, run_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Import run not found")
    return obj
