from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.inventory import InventoryTransaction
from app.db.session import get_db
from app.schemas.inventory import InventoryTransactionCreate, InventoryTransactionOut, InventoryTransactionUpdate

router = APIRouter()


@router.get("", response_model=list[InventoryTransactionOut])
def list_inventory_transactions(
    project_id: int | None = None,
    material_id: int | None = None,
    task_id: int | None = None,
    transaction_type: str | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    sort_by: str = Query(default="inv_tx_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(InventoryTransaction)
    if project_id is not None:
        stmt = stmt.where(InventoryTransaction.project_id == project_id)
    if material_id is not None:
        stmt = stmt.where(InventoryTransaction.material_id == material_id)
    if task_id is not None:
        stmt = stmt.where(InventoryTransaction.task_id == task_id)
    if transaction_type is not None:
        stmt = stmt.where(InventoryTransaction.transaction_type == transaction_type)

    if date_from is not None:
        stmt = stmt.where(InventoryTransaction.transaction_date >= date_from)
    if date_to is not None:
        stmt = stmt.where(InventoryTransaction.transaction_date <= date_to)

    sort_map = {
        "inv_tx_id": InventoryTransaction.inv_tx_id,
        "project_id": InventoryTransaction.project_id,
        "material_id": InventoryTransaction.material_id,
        "task_id": InventoryTransaction.task_id,
        "po_item_id": InventoryTransaction.po_item_id,
        "transaction_type": InventoryTransaction.transaction_type,
        "quantity": InventoryTransaction.quantity,
        "unit_price": InventoryTransaction.unit_price,
        "transaction_date": InventoryTransaction.transaction_date,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    stmt = stmt.order_by(col).limit(limit).offset(offset)
    return db.execute(stmt).scalars().all()


@router.get("/{inv_tx_id}", response_model=InventoryTransactionOut)
def get_inventory_transaction(inv_tx_id: int, db: Session = Depends(get_db)):
    obj = db.get(InventoryTransaction, inv_tx_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Inventory transaction not found")
    return obj


@router.post("", response_model=InventoryTransactionOut, status_code=201)
def create_inventory_transaction(payload: InventoryTransactionCreate, db: Session = Depends(get_db)):
    obj = InventoryTransaction(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{inv_tx_id}", response_model=InventoryTransactionOut)
def update_inventory_transaction(inv_tx_id: int, payload: InventoryTransactionUpdate, db: Session = Depends(get_db)):
    obj = db.get(InventoryTransaction, inv_tx_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Inventory transaction not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{inv_tx_id}", status_code=204)
def delete_inventory_transaction(inv_tx_id: int, db: Session = Depends(get_db)):
    obj = db.get(InventoryTransaction, inv_tx_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Inventory transaction not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
