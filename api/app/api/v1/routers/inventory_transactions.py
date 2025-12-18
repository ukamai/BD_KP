from fastapi import APIRouter, Depends, HTTPException
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
    return db.execute(stmt.order_by(InventoryTransaction.inv_tx_id)).scalars().all()


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
