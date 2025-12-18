from pydantic import BaseModel, Field


class PropertyOut(BaseModel):
    property_id: int
    owner_id: int
    address: str
    property_type: str
    total_area: float
    status: str

    class Config:
        from_attributes = True


class PropertyCreate(BaseModel):
    owner_id: int
    address: str = Field(min_length=1, max_length=200)
    property_type: str = Field(min_length=1, max_length=20)
    total_area: float = Field(gt=0)
    status: str = Field(default="active", max_length=20)


class PropertyUpdate(BaseModel):
    owner_id: int | None = None
    address: str | None = Field(default=None, min_length=1, max_length=200)
    property_type: str | None = Field(default=None, min_length=1, max_length=20)
    total_area: float | None = Field(default=None, gt=0)
    status: str | None = Field(default=None, max_length=20)


class RoomOut(BaseModel):
    room_id: int
    property_id: int
    room_name: str
    room_type: str
    area: float
    ceiling_height: float | None
    has_window: bool
    notes: str | None

    class Config:
        from_attributes = True


class RoomCreate(BaseModel):
    property_id: int
    room_name: str = Field(min_length=1, max_length=50)
    room_type: str = Field(min_length=1, max_length=30)
    area: float = Field(gt=0)
    ceiling_height: float | None = Field(default=None, gt=0)
    has_window: bool = False
    notes: str | None = None


class RoomUpdate(BaseModel):
    property_id: int | None = None
    room_name: str | None = Field(default=None, min_length=1, max_length=50)
    room_type: str | None = Field(default=None, min_length=1, max_length=30)
    area: float | None = Field(default=None, gt=0)
    ceiling_height: float | None = Field(default=None, gt=0)
    has_window: bool | None = None
    notes: str | None = None
