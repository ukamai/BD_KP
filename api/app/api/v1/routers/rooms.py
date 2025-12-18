from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session

from app.db.models.property import PropertyRoom
from app.db.session import get_db
from app.schemas.property import RoomCreate, RoomOut, RoomUpdate

router = APIRouter()


@router.get("", response_model=list[RoomOut])
def list_rooms(property_id: int | None = None, db: Session = Depends(get_db)):
    stmt = select(PropertyRoom)
    if property_id is not None:
        stmt = stmt.where(PropertyRoom.property_id == property_id)
    return db.execute(stmt.order_by(PropertyRoom.room_id)).scalars().all()


@router.get("/{room_id}", response_model=RoomOut)
def get_room(room_id: int, db: Session = Depends(get_db)):
    obj = db.get(PropertyRoom, room_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Room not found")
    return obj


@router.post("", response_model=RoomOut, status_code=201)
def create_room(payload: RoomCreate, db: Session = Depends(get_db)):
    obj = PropertyRoom(**payload.model_dump())
    db.add(obj)
    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.patch("/{room_id}", response_model=RoomOut)
def update_room(room_id: int, payload: RoomUpdate, db: Session = Depends(get_db)):
    obj = db.get(PropertyRoom, room_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Room not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)

    try:
        db.commit()
        db.refresh(obj)
        return obj
    except (IntegrityError, DataError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB error: {str(getattr(e, 'orig', e)).strip()}")


@router.delete("/{room_id}", status_code=204)
def delete_room(room_id: int, db: Session = Depends(get_db)):
    obj = db.get(PropertyRoom, room_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Room not found")
    db.delete(obj)
    try:
        db.commit()
        return None
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"DB integrity error: {str(e.orig).strip()}")
