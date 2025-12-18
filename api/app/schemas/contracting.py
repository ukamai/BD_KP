from datetime import date

from pydantic import BaseModel, Field


class ContractorOut(BaseModel):
    contractor_id: int
    name: str
    inn: str
    phone: str | None
    email: str | None
    specialization: str | None
    rating: float | None

    class Config:
        from_attributes = True


class ContractorCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    inn: str = Field(min_length=10, max_length=12)
    phone: str | None = Field(default=None, max_length=20)
    email: str | None = Field(default=None, max_length=100)
    specialization: str | None = Field(default=None, max_length=100)
    rating: float | None = Field(default=None, ge=0, le=5)


class ContractorUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    inn: str | None = Field(default=None, min_length=10, max_length=12)
    phone: str | None = Field(default=None, max_length=20)
    email: str | None = Field(default=None, max_length=100)
    specialization: str | None = Field(default=None, max_length=100)
    rating: float | None = Field(default=None, ge=0, le=5)


class ContractOut(BaseModel):
    contract_id: int
    property_id: int
    contractor_id: int
    contract_number: str
    status: str
    total_amount: float
    start_date: date
    end_date: date | None
    signed_at: date | None

    class Config:
        from_attributes = True


class ContractCreate(BaseModel):
    property_id: int
    contractor_id: int
    contract_number: str = Field(min_length=1, max_length=50)
    status: str = Field(default="draft", max_length=20)
    total_amount: float = Field(ge=0)
    start_date: date
    end_date: date | None = None
    signed_at: date | None = None


class ContractUpdate(BaseModel):
    property_id: int | None = None
    contractor_id: int | None = None
    contract_number: str | None = Field(default=None, min_length=1, max_length=50)
    status: str | None = Field(default=None, max_length=20)
    total_amount: float | None = Field(default=None, ge=0)
    start_date: date | None = None
    end_date: date | None = None
    signed_at: date | None = None
