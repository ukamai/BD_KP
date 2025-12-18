from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.property import Property, PropertyRoom
from app.db.session import get_db
from app.schemas.property import PropertyCreate, PropertyOut, PropertyUpdate, RoomOut

router = APIRouter()


@router.get("", response_model=list[PropertyOut])
def list_properties(db: Session = Depends(get_db)):
    return db.execute(select(Property).order_by(Property.property_id)).scalars().all()


@router.get("/{property_id}", response_model=PropertyOut)
def get_property(property_id: int, db: Session = Depends(get_db)):
    obj = db.get(Property, property_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Property not found")
    return obj


@router.post("", response_model=PropertyOut, status_code=201)
def create_property(payload: PropertyCreate, db: Session = Depends(get_db)):
    obj = Property(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{property_id}", response_model=PropertyOut)
def update_property(property_id: int, payload: PropertyUpdate, db: Session = Depends(get_db)):
    obj = db.get(Property, property_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Property not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{property_id}", status_code=204)
def delete_property(property_id: int, db: Session = Depends(get_db)):
    obj = db.get(Property, property_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Property not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")


@router.get("/{property_id}/rooms", response_model=list[RoomOut])
def list_property_rooms(property_id: int, db: Session = Depends(get_db)):
    return db.execute(
        select(PropertyRoom).where(PropertyRoom.property_id == property_id).order_by(PropertyRoom.room_id)
    ).scalars().all()
