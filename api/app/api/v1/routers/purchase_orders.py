from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.purchase import PurchaseOrder, PurchaseOrderItem
from app.schemas.purchase import PurchaseOrderCreate, PurchaseOrderOut

router = APIRouter()

def _gen_po_number() -> str:
    # чтобы гарантированно не ловить конфликт UNIQUE(po_number)
    return "PO-API-" + datetime.utcnow().strftime("%Y%m%d%H%M%S%f")

@router.post("", response_model=PurchaseOrderOut, status_code=201)
def create_purchase_order(payload: PurchaseOrderCreate, db: Session = Depends(get_db)):
    po_number = _gen_po_number()

    try:
        with db.begin():
            po = PurchaseOrder(
                project_id=payload.project_id,
                supplier_id=payload.supplier_id,
                po_number=po_number,
                status=payload.status,
                total_amount=0,
                order_date=payload.order_date,
                expected_delivery_date=payload.expected_delivery_date,
            )
            db.add(po)
            db.flush()  # получаем po_id

            for item in payload.items:
                line_total = float(item.quantity_ordered) * float(item.unit_price)
                poi = PurchaseOrderItem(
                    po_id=po.po_id,
                    material_id=item.material_id,
                    quantity_ordered=item.quantity_ordered,
                    unit_price=item.unit_price,
                    delivered_quantity=0,
                    line_total=line_total,
                )
                db.add(poi)

        # после транзакции обновляем объект (триггер мог пересчитать total_amount)
        db.refresh(po)
        return po

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create purchase order: {e}")

@router.get("/{po_id}", response_model=PurchaseOrderOut)
def get_purchase_order(po_id: int, db: Session = Depends(get_db)):
    po = db.get(PurchaseOrder, po_id)
    if not po:
        raise HTTPException(status_code=404, detail="Purchase order not found")
    return po

@router.get("/{po_id}/items")
def list_purchase_order_items(po_id: int, db: Session = Depends(get_db)):
    rows = db.execute(
        select(PurchaseOrderItem).where(PurchaseOrderItem.po_id == po_id).order_by(PurchaseOrderItem.po_item_id)
    ).scalars().all()
    return rows
