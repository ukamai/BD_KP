from pydantic import BaseModel


class MaterialCreate(BaseModel):
    material_name: str
    category: str | None = None
    unit: str
    manufacturer: str | None = None
    current_price: float = 0
    is_active: bool = True


class MaterialUpdate(BaseModel):
    material_name: str | None = None
    category: str | None = None
    unit: str | None = None
    manufacturer: str | None = None
    current_price: float | None = None
    is_active: bool | None = None


class MaterialOut(BaseModel):
    material_id: int
    material_name: str
    category: str | None
    unit: str
    manufacturer: str | None
    current_price: float
    is_active: bool

    class Config:
        from_attributes = True


class SupplierOut(BaseModel):
    supplier_id: int
    supplier_name: str
    phone: str | None
    email: str | None
    address: str | None
    contact_person: str | None

    class Config:
        from_attributes = True


class SupplierCreate(BaseModel):
    supplier_name: str
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    contact_person: str | None = None


class SupplierUpdate(BaseModel):
    supplier_name: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    contact_person: str | None = None
