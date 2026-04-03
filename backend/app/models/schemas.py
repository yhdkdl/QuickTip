from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional
from uuid import UUID
from datetime import datetime
import re


class PayoutMethodBase(BaseModel):
    method: str

    @field_validator("method")
    @classmethod
    def validate_method(cls, v):
        if v not in ["telebirr", "bank"]:
            raise ValueError("Payout method must be 'telebirr' or 'bank'")
        return v


class TelebirrPayout(PayoutMethodBase):
    method: str = "telebirr"
    telebirr_phone: str

    @field_validator("telebirr_phone")
    @classmethod
    def validate_telebirr_phone(cls, v):
        pattern = r"^(09|07)\d{8}$|^(2519|2517)\d{8}$"
        if not re.match(pattern, v):
            raise ValueError("Telebirr phone must be a valid Ethiopian number")
        return v


class BankPayout(PayoutMethodBase):
    method: str = "bank"
    bank_name: str
    account_number: str
    account_name: str

    @field_validator("bank_name")
    @classmethod
    def validate_bank_name(cls, v):
        if len(v.strip()) < 2:
            raise ValueError("Bank name is required")
        return v.strip()

    @field_validator("account_number")
    @classmethod
    def validate_account_number(cls, v):
        cleaned = v.replace(" ", "").replace("-", "")
        if len(cleaned) < 5:
            raise ValueError("Invalid account number")
        return cleaned

    @field_validator("account_name")
    @classmethod
    def validate_account_name(cls, v):
        if len(v.strip()) < 2:
            raise ValueError("Account name is required")
        return v.strip()


class WorkerRegister(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    password: str
    profession: Optional[str] = None

    # Payout fields
    payout_method: str
    telebirr_phone: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    account_name: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        pattern = r"^(09|07)\d{8}$|^(2519|2517)\d{8}$"
        if not re.match(pattern, v):
            raise ValueError(
                "Phone must be a valid Ethiopian number e.g. 0911234567"
            )
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

    @field_validator("payout_method")
    @classmethod
    def validate_payout_method(cls, v):
        if v not in ["telebirr", "bank"]:
            raise ValueError("payout_method must be 'telebirr' or 'bank'")
        return v

    @model_validator(mode="after")
    def validate_payout_details(self):
        if self.payout_method == "telebirr":
            if not self.telebirr_phone:
                raise ValueError(
                    "telebirr_phone is required when payout_method is 'telebirr'"
                )
            pattern = r"^(09|07)\d{8}$|^(2519|2517)\d{8}$"
            if not re.match(pattern, self.telebirr_phone):
                raise ValueError("Invalid Telebirr phone number")

        if self.payout_method == "bank":
            if not self.bank_name:
                raise ValueError(
                    "bank_name is required when payout_method is 'bank'"
                )
            if not self.account_number:
                raise ValueError(
                    "account_number is required when payout_method is 'bank'"
                )
            if not self.account_name:
                raise ValueError(
                    "account_name is required when payout_method is 'bank'"
                )
        return self


class WorkerLogin(BaseModel):
    phone: str
    password: str


class PayoutAccountResponse(BaseModel):
    id: UUID
    method: str
    telebirr_phone: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    account_name: Optional[str] = None


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
    payout_account: Optional[PayoutAccountResponse] = None


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
        pattern = r"^(09|07)\d{8}$|^(2519|2517)\d{8}$"
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


class PayoutResponse(BaseModel):
    id: UUID
    tip_id: UUID
    amount: float
    method: str
    status: str
    attempts: int
    failure_reason: Optional[str] = None
    created_at: datetime