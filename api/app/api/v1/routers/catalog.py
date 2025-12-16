from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.catalog import Material, Supplier
from app.schemas.catalog import MaterialOut, SupplierOut

router = APIRouter()

@router.get("/materials", response_model=list[MaterialOut])
def list_materials(db: Session = Depends(get_db)):
    return db.execute(select(Material).order_by(Material.material_id)).scalars().all()

@router.get("/suppliers", response_model=list[SupplierOut])
def list_suppliers(db: Session = Depends(get_db)):
    return db.execute(select(Supplier).order_by(Supplier.supplier_id)).scalars().all()
