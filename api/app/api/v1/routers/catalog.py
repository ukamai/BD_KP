from fastapi import APIRouter, Depends, HTTPException
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
def list_materials(db: Session = Depends(get_db)):
    return db.execute(select(Material).order_by(Material.material_id)).scalars().all()


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
def list_suppliers(db: Session = Depends(get_db)):
    return db.execute(select(Supplier).order_by(Supplier.supplier_id)).scalars().all()


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
