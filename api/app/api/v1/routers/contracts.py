from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.contracting import Contract
from app.db.models.project import Project
from app.db.session import get_db
from app.schemas.contracting import ContractCreate, ContractOut, ContractUpdate

router = APIRouter()


@router.get("", response_model=list[ContractOut])
def list_contracts(
    property_id: int | None = None,
    contractor_id: int | None = None,
    project_id: int | None = None,
    db: Session = Depends(get_db),
):
    stmt = select(Contract)
    if property_id is not None:
        stmt = stmt.where(Contract.property_id == property_id)
    if contractor_id is not None:
        stmt = stmt.where(Contract.contractor_id == contractor_id)
    if project_id is not None:
        stmt = stmt.join(Project, Project.contract_id == Contract.contract_id).where(Project.project_id == project_id)
    return db.execute(stmt.order_by(Contract.contract_id)).scalars().all()


@router.get("/{contract_id}", response_model=ContractOut)
def get_contract(contract_id: int, db: Session = Depends(get_db)):
    obj = db.get(Contract, contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")
    return obj


@router.post("", response_model=ContractOut, status_code=201)
def create_contract(payload: ContractCreate, db: Session = Depends(get_db)):
    obj = Contract(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{contract_id}", response_model=ContractOut)
def update_contract(contract_id: int, payload: ContractUpdate, db: Session = Depends(get_db)):
    obj = db.get(Contract, contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{contract_id}", status_code=204)
def delete_contract(contract_id: int, db: Session = Depends(get_db)):
    obj = db.get(Contract, contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
