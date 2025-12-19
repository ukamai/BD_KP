from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, DataError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.catalog import Material, Supplier
from app.schemas.catalog import (
    MaterialOut,
    MaterialCreate,
    MaterialUpdate,
    SupplierOut,
    SupplierCreate,
    SupplierUpdate,
)

router = APIRouter()


@router.get("/materials", response_model=list[MaterialOut])
def list_materials(
    category: str | None = None,
    is_active: bool | None = None,
    q: str | None = None,
    sort_by: str = Query(default="material_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Material)
    if category is not None:
        stmt = stmt.where(Material.category == category)
    if is_active is not None:
        stmt = stmt.where(Material.is_active == is_active)
    if q:
        stmt = stmt.where(Material.material_name.ilike(f"%{q}%"))

    sort_map = {
        "material_id": Material.material_id,
        "material_name": Material.material_name,
        "category": Material.category,
        "unit": Material.unit,
        "manufacturer": Material.manufacturer,
        "current_price": Material.current_price,
        "is_active": Material.is_active,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    return db.execute(stmt.order_by(col).limit(limit).offset(offset)).scalars().all()


@router.get("/materials/{material_id}", response_model=MaterialOut)
def get_material(material_id: int, db: Session = Depends(get_db)):
    obj = db.get(Material, material_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Material not found")
    return obj


@router.post("/materials", response_model=MaterialOut, status_code=201)
def create_material(payload: MaterialCreate, db: Session = Depends(get_db)):
    obj = Material(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.patch("/materials/{material_id}", response_model=MaterialOut)
def update_material(material_id: int, payload: MaterialUpdate, db: Session = Depends(get_db)):
    obj = db.get(Material, material_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Material not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.delete("/materials/{material_id}", status_code=204)
def delete_material(material_id: int, db: Session = Depends(get_db)):
    obj = db.get(Material, material_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Material not found")

    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")


@router.get("/suppliers", response_model=list[SupplierOut])
def list_suppliers(
    q: str | None = None,
    sort_by: str = Query(default="supplier_id"),
    sort_dir: str = Query(default="asc", pattern="^(asc|desc)$"),
    limit: int = Query(default=200, ge=1, le=2000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Supplier)
    if q:
        stmt = stmt.where(Supplier.supplier_name.ilike(f"%{q}%"))

    sort_map = {
        "supplier_id": Supplier.supplier_id,
        "supplier_name": Supplier.supplier_name,
        "created_at": Supplier.created_at,
    }
    col = sort_map.get(sort_by)
    if col is None:
        raise HTTPException(status_code=400, detail="Invalid sort_by")
    col = col.desc() if sort_dir == "desc" else col.asc()

    return db.execute(stmt.order_by(col).limit(limit).offset(offset)).scalars().all()


@router.get("/suppliers/{supplier_id}", response_model=SupplierOut)
def get_supplier(supplier_id: int, db: Session = Depends(get_db)):
    obj = db.get(Supplier, supplier_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return obj


@router.post("/suppliers", response_model=SupplierOut, status_code=201)
def create_supplier(payload: SupplierCreate, db: Session = Depends(get_db)):
    obj = Supplier(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.patch("/suppliers/{supplier_id}", response_model=SupplierOut)
def update_supplier(supplier_id: int, payload: SupplierUpdate, db: Session = Depends(get_db)):
    obj = db.get(Supplier, supplier_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Supplier not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
    except DataError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB data error: {str(e.orig).strip()}")


@router.delete("/suppliers/{supplier_id}", status_code=204)
def delete_supplier(supplier_id: int, db: Session = Depends(get_db)):
    obj = db.get(Supplier, supplier_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Supplier not found")

    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
