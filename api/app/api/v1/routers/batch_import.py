import json
import random
import re
from datetime import date, timedelta

from faker import Faker
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.imports import (
    BatchImportFakerRequest,
    BatchImportRequest,
    BatchImportResponse,
    InventoryTransactionImportItem,
)

router = APIRouter()
public_router = APIRouter()


def _fetch_int_list(db: Session, sql: str) -> list[int]:
    rows = db.execute(text(sql)).all()
    out: list[int] = []
    for r in rows:
        if r and r[0] is not None:
            out.append(int(r[0]))
    return out


def _pick_date_in_range(d_from: date | None, d_to: date | None) -> date:
    if d_from and d_to and d_from <= d_to:
        days = (d_to - d_from).days
        return d_from + timedelta(days=random.randint(0, days))
    if d_from and not d_to:
        return d_from
    if d_to and not d_from:
        return d_to
    return _random_date(days_back=90)


def _normalize_type(t: str) -> str:
    t = (t or "").strip().upper()
    t = re.sub(r"\s+", "_", t)
    return t[:50]


def _random_date(days_back: int = 90) -> date:
    return date.today() - timedelta(days=random.randint(0, max(days_back, 0)))


def _tasks_by_project(db: Session) -> dict[int, list[int]]:
    try:
        rows = db.execute(
            text(
                """
                SELECT project_id, task_id
                FROM project_tasks
                WHERE project_id IS NOT NULL AND task_id IS NOT NULL
                """
            )
        ).all()
    except Exception:
        db.rollback()
        return {}

    m: dict[int, list[int]] = {}
    for project_id, task_id in rows:
        if project_id is None or task_id is None:
            continue
        m.setdefault(int(project_id), []).append(int(task_id))
    return m


def _po_items_by_project(db: Session) -> dict[int, list[int]]:
    try:
        rows = db.execute(
            text(
                """
                SELECT po.project_id, poi.po_item_id
                FROM purchase_order_items poi
                JOIN purchase_orders po ON po.po_id = poi.po_id
                """
            )
        ).all()
    except Exception:
        db.rollback()
        return {}

    m: dict[int, list[int]] = {}
    for project_id, po_item_id in rows:
        if project_id is None or po_item_id is None:
            continue
        m.setdefault(int(project_id), []).append(int(po_item_id))
    return m


def _call_batch_import_fn(
    db: Session,
    items: list[InventoryTransactionImportItem],
    source: str | None,
    fail_fast: bool,
    meta: dict | None,
) -> dict:
    payload = [i.model_dump() for i in items]
    items_json = json.dumps(payload, ensure_ascii=False, default=str)
    meta_json = json.dumps(meta or {}, ensure_ascii=False, default=str)

    row = db.execute(
        text(
            """
            SELECT run_id, total_rows, inserted_rows, failed_rows, status
            FROM fn_batch_import_inventory_transactions(
              CAST(:items_json AS jsonb),
              CAST(:source AS text),
              CAST(:fail_fast AS boolean),
              CAST(:meta_json AS jsonb)
            )
            """
        ),
        {"items_json": items_json, "source": source or "api", "fail_fast": fail_fast, "meta_json": meta_json},
    ).mappings().first()

    if not row:
        return {"run_id": None, "total": 0, "inserted": 0, "failed": 0, "status": "unknown"}

    return {
        "run_id": int(row["run_id"]),
        "total": int(row["total_rows"]),
        "inserted": int(row["inserted_rows"]),
        "failed": int(row["failed_rows"]),
        "status": str(row["status"]),
    }


def _make_valid_qty_price(tx_type: str) -> tuple[float, float]:
    t = _normalize_type(tx_type)
    quantity = round(random.uniform(0.1, 50.0), 2)
    if t == "IN":
        unit_price = round(random.uniform(1.0, 5000.0), 2)
        return quantity, unit_price
    if t == "OUT":
        return quantity, 0.0
    return quantity, 0.0


@router.post("/batch", response_model=BatchImportResponse)
def batch_import_inventory_transactions(payload: BatchImportRequest, db: Session = Depends(get_db)):
    try:
        res = _call_batch_import_fn(db, payload.items, payload.source, payload.fail_fast, meta=None)
        db.commit()
        return BatchImportResponse(**res)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Batch import failed: {str(e)}")


@router.post("/batch/faker", response_model=BatchImportResponse)
def batch_import_inventory_transactions_faker(payload: BatchImportFakerRequest, db: Session = Depends(get_db)):
    faker = Faker("ru_RU")
    seed = payload.seed or random.randint(1, 10_000_000)
    Faker.seed(seed)
    random.seed(seed)

    project_ids = _fetch_int_list(db, "SELECT project_id FROM projects ORDER BY project_id")
    material_ids = _fetch_int_list(db, "SELECT material_id FROM materials ORDER BY material_id")

    if payload.project_id is not None:
        project_ids = [payload.project_id]
    if payload.material_id is not None:
        material_ids = [payload.material_id]

    if not project_ids:
        project_ids = [1]
    if not material_ids:
        material_ids = [1]

    tasks_map = _tasks_by_project(db) if payload.allow_task_id else {}
    po_items_map = _po_items_by_project(db) if payload.allow_po_item_id else {}

    tx_types = list(payload.transaction_types or ["IN", "OUT", "ADJUST"])
    tx_types = [_normalize_type(t) for t in tx_types if t and t.strip()]
    tx_types = [t for t in tx_types if t in {"IN", "OUT", "ADJUST"}]
    if not tx_types:
        tx_types = ["IN", "OUT", "ADJUST"]

    items: list[InventoryTransactionImportItem] = []

    for _ in range(payload.count):
        make_invalid = random.random() < float(payload.invalid_rate or 0.0)

        project_id = random.choice(project_ids)
        material_id = random.choice(material_ids)

        task_id = None
        if payload.allow_task_id:
            candidates = tasks_map.get(int(project_id), [])
            task_id = random.choice(candidates) if candidates else None
        if payload.task_id is not None:
            task_id = payload.task_id

        po_item_id = None
        if payload.allow_po_item_id:
            candidates = po_items_map.get(int(project_id), [])
            po_item_id = random.choice(candidates) if candidates else None
        if payload.po_item_id is not None:
            po_item_id = payload.po_item_id

        transaction_type = random.choice(tx_types)
        quantity, unit_price = _make_valid_qty_price(transaction_type)
        transaction_date = _pick_date_in_range(payload.date_from, payload.date_to)
        comment = faker.sentence(nb_words=random.randint(3, 10))

        if make_invalid:
            mode = random.choice(["bad_fk", "bad_type", "bad_qty_price"])
            if mode == "bad_fk":
                material_id = int(max(material_ids) + random.randint(1, 10_000)) if material_ids else 999999
            elif mode == "bad_type":
                transaction_type = "INVALID_TYPE_###"
            else:
                quantity = -abs(quantity)

        items.append(
            InventoryTransactionImportItem(
                project_id=int(project_id),
                material_id=int(material_id),
                task_id=int(task_id) if task_id is not None else None,
                po_item_id=int(po_item_id) if po_item_id is not None else None,
                transaction_type=transaction_type,
                quantity=float(quantity),
                unit_price=float(unit_price),
                transaction_date=transaction_date,
                comment=comment,
            )
        )

    try:
        meta = {
            "generator": "faker",
            "seed": seed,
            "count": payload.count,
            "invalid_rate": float(payload.invalid_rate or 0.0),
        }
        res = _call_batch_import_fn(db, items, payload.source, payload.fail_fast, meta=meta)
        db.commit()
        return BatchImportResponse(**res)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Batch import faker failed: {str(e)}")


@public_router.post("/batch-import/inventory-transactions", response_model=BatchImportResponse)
def public_batch_import_inventory_transactions(payload: BatchImportRequest, db: Session = Depends(get_db)):
    return batch_import_inventory_transactions(payload, db)


@public_router.post("/batch-import/inventory-transactions/faker", response_model=BatchImportResponse)
def public_batch_import_inventory_transactions_faker(payload: BatchImportFakerRequest, db: Session = Depends(get_db)):
    return batch_import_inventory_transactions_faker(payload, db)
