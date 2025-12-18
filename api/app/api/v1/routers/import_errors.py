from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.imports import ImportError

router = APIRouter()


@router.get("", response_model=list[dict])
def list_import_errors(source: str | None = None, limit: int = 200, db: Session = Depends(get_db)):
    stmt = select(ImportError).order_by(ImportError.error_id.desc()).limit(limit)
    if source:
        stmt = stmt.where(ImportError.source == source)
    rows = db.execute(stmt).scalars().all()

    return [
        {
            "error_id": r.error_id,
            "occurred_at": r.occurred_at,
            "source": r.source,
            "payload": r.payload,
            "error_message": r.error_message,
            "user_id": r.user_id,
            "details": r.details,
        }
        for r in rows
    ]