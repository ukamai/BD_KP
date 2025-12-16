from pydantic import BaseModel


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
