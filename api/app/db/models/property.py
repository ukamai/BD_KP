from datetime import datetime

from sqlalchemy import BigInteger, Boolean, Numeric, String, TIMESTAMP, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Property(Base):
    __tablename__ = "properties"

    property_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    owner_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    address: Mapped[str] = mapped_column(String(200), nullable=False)
    property_type: Mapped[str] = mapped_column(String(20), nullable=False)
    total_area: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
    updated_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))


class PropertyRoom(Base):
    __tablename__ = "property_rooms"

    room_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    property_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    room_name: Mapped[str] = mapped_column(String(50), nullable=False)
    room_type: Mapped[str] = mapped_column(String(30), nullable=False)
    area: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    ceiling_height: Mapped[float | None] = mapped_column(Numeric(4, 2), nullable=True)
    has_window: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    notes: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text("now()"))
