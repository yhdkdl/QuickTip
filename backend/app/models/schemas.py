from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from uuid import UUID
from datetime import datetime
import re


class WorkerRegister(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    password: str
    profession: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        pattern = r"^2519\d{8}$|^2517\d{8}$|^09\d{8}$|^07\d{8}$"
        if not re.match(pattern, v):
            raise ValueError("Phone must be a valid Ethiopian number e.g. 0911234567")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v):
        if len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v.strip()


class WorkerLogin(BaseModel):
    phone: str
    password: str


class WorkerResponse(BaseModel):
    id: UUID
    name: str
    phone: str
    email: Optional[str] = None
    profession: Optional[str] = None
    avatar_url: Optional[str] = None
    qr_code_url: Optional[str] = None
    nfc_enabled: bool
    is_active: bool
    created_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    worker: WorkerResponse


class WorkerProfileUpdate(BaseModel):
    name: Optional[str] = None
    profession: Optional[str] = None
    email: Optional[EmailStr] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v):
        if v is not None and len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v.strip() if v else v


class PublicWorkerResponse(BaseModel):
    id: UUID
    name: str
    profession: Optional[str] = None
    avatar_url: Optional[str] = None
    qr_code_url: Optional[str] = None


class QRCodeResponse(BaseModel):
    qr_code_url: str
    tip_url: str


class TipInitiate(BaseModel):
    worker_id: str
    amount: float
    customer_phone: str
    customer_email: Optional[str] = None
    initiated_via: str = "qr"

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v):
        if v < 1:
            raise ValueError("Minimum tip amount is ETB 1")
        if v > 100000:
            raise ValueError("Maximum tip amount is ETB 100,000")
        return round(v, 2)

    @field_validator("customer_phone")
    @classmethod
    def validate_customer_phone(cls, v):
        pattern = r"^2519\d{8}$|^2517\d{8}$|^09\d{8}$|^07\d{8}$"
        if not re.match(pattern, v):
            raise ValueError("Phone must be a valid Ethiopian number")
        return v

    @field_validator("initiated_via")
    @classmethod
    def validate_initiated_via(cls, v):
        if v not in ["qr", "nfc"]:
            raise ValueError("initiated_via must be qr or nfc")
        return v


class TipSessionResponse(BaseModel):
    session_id: str
    status: str
    amount: float
    worker_name: str
    message: str
    checkout_url: Optional[str] = None


class ChapaWebhookPayload(BaseModel):
    event: Optional[str] = None
    tx_ref: str
    status: str


class WebSocketMessage(BaseModel):
    type: str
    session_id: str
    status: str
    amount: Optional[float] = None
    worker_name: Optional[str] = None
    payment_reference: Optional[str] = None
    message: str