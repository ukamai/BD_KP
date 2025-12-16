from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.imports import ImportError
from app.schemas.imports import BatchImportRequest, BatchImportResult

router = APIRouter()

@router.post("/batch", response_model=BatchImportResult)
def batch_import_inventory_transactions(payload: BatchImportRequest, db: Session = Depends(get_db)):
    errors_before = db.execute(
        text("SELECT COUNT(*) FROM import_errors WHERE source = :src"),
        {"src": payload.source},
    ).scalar_one()

    call_sql = text("""
        CALL sp_batch_import_inventory_transactions(
          :rows::jsonb,
          :source,
          :fail_fast
        )
    """)

    rows_as_dicts = [r.model_dump() for r in payload.rows]

    db.execute(call_sql, {"rows": rows_as_dicts, "source": payload.source, "fail_fast": payload.fail_fast})
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
