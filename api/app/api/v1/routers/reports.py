from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db

router = APIRouter()

@router.get("/projects")
def report_projects(
    status: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    db: Session = Depends(get_db),
):
    q = text("""
        SELECT *
        FROM fn_report_projects(:status, :date_from, :date_to)
    """)
    rows = db.execute(q, {"status": status, "date_from": date_from, "date_to": date_to}).mappings().all()
    return rows
