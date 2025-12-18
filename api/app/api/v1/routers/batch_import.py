from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.imports import BatchImportRequest, BatchImportResult

router = APIRouter()
public_router = APIRouter()


def _run_batch_import(payload: BatchImportRequest, db: Session) -> BatchImportResult:
    errors_before = db.execute(
        text("SELECT COUNT(*) FROM import_errors WHERE source = :src"),
        {"src": payload.source},
    ).scalar_one()

    rows_as_dicts = [r.model_dump() for r in payload.rows]

    db.execute(
        text("CALL sp_batch_import_inventory_transactions(:src, :rows::jsonb)"),
        {"src": payload.source, "rows": rows_as_dicts},
    )
    db.commit()

    errors_after = db.execute(
        text("SELECT COUNT(*) FROM import_errors WHERE source = :src"),
        {"src": payload.source},
    ).scalar_one()

    return BatchImportResult(
        ok=True,
        rows_received=len(rows_as_dicts),
        errors_before=int(errors_before),
        errors_after=int(errors_after),
        errors_added=int(errors_after - errors_before),
    )


@router.post("/batch", response_model=BatchImportResult)
def batch_import_inventory_transactions(payload: BatchImportRequest, db: Session = Depends(get_db)):
    return _run_batch_import(payload, db)


@public_router.post("/batch-import", response_model=BatchImportResult)
def batch_import_alias(payload: BatchImportRequest, db: Session = Depends(get_db)):
    return _run_batch_import(payload, db)