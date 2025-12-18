from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.contracting import Contractor
from app.db.session import get_db
from app.schemas.contracting import ContractorCreate, ContractorOut, ContractorUpdate

router = APIRouter()


@router.get("", response_model=list[ContractorOut])
def list_contractors(db: Session = Depends(get_db)):
    return db.execute(select(Contractor).order_by(Contractor.contractor_id)).scalars().all()


@router.get("/{contractor_id}", response_model=ContractorOut)
def get_contractor(contractor_id: int, db: Session = Depends(get_db)):
    obj = db.get(Contractor, contractor_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contractor not found")
    return obj


@router.post("", response_model=ContractorOut, status_code=201)
def create_contractor(payload: ContractorCreate, db: Session = Depends(get_db)):
    obj = Contractor(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{contractor_id}", response_model=ContractorOut)
def update_contractor(contractor_id: int, payload: ContractorUpdate, db: Session = Depends(get_db)):
    obj = db.get(Contractor, contractor_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contractor not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{contractor_id}", status_code=204)
def delete_contractor(contractor_id: int, db: Session = Depends(get_db)):
    obj = db.get(Contractor, contractor_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contractor not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
