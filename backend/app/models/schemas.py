from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional
from uuid import UUID
from datetime import datetime
import re


# ─────────────────────────────────────────
# SHARED VALIDATORS
# ─────────────────────────────────────────

def validate_ethiopian_phone(v: str) -> str:
    pattern = r"^(09|07)\d{8}$|^(2519|2517)\d{8}$"
    if not re.match(pattern, v):
        raise ValueError(
            "Phone must be a valid Ethiopian number e.g. 0911234567"
        )
    return v


# ─────────────────────────────────────────
# PAYOUT ACCOUNT SCHEMAS
# ─────────────────────────────────────────

class PayoutAccountCreate(BaseModel):
    method: str
    telebirr_phone: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    account_name: Optional[str] = None

    @field_validator("method")
    @classmethod
    def validate_method(cls, v):
        if v not in ["telebirr", "bank"]:
            raise ValueError("method must be telebirr or bank")
        return v

    @model_validator(mode="after")
    def validate_payout_details(self):
        if self.method == "telebirr":
            if not self.telebirr_phone:
                raise ValueError(
                    "telebirr_phone is required for Telebirr payouts"
                )
            validate_ethiopian_phone(self.telebirr_phone)

        if self.method == "bank":
            missing = []
            if not self.bank_name:
                missing.append("bank_name")
            if not self.account_number:
                missing.append("account_number")
            if not self.account_name:
                missing.append("account_name")
            if missing:
                raise ValueError(
                    f"Bank payout requires: {', '.join(missing)}"
                )
        return self


class PayoutAccountResponse(BaseModel):
    id: UUID
    method: str
    telebirr_phone: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    account_name: Optional[str] = None
    is_default: bool
    created_at: datetime


class PayoutAccountListResponse(BaseModel):
    accounts: list[PayoutAccountResponse]
    total: int


# ─────────────────────────────────────────
# WORKER SCHEMAS
# ─────────────────────────────────────────

class WorkerRegister(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    password: str
    profession: Optional[str] = None
    payout: PayoutAccountCreate

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        return validate_ethiopian_phone(v)

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


class PublicWorkerResponse(BaseModel):
    id: UUID
    name: str
    profession: Optional[str] = None
    avatar_url: Optional[str] = None
    qr_code_url: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    worker: WorkerResponse


class QRCodeResponse(BaseModel):
    qr_code_url: str
    tip_url: str


# ─────────────────────────────────────────
# TIP SCHEMAS
# ─────────────────────────────────────────

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
        return validate_ethiopian_phone(v)

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


# ─────────────────────────────────────────
# CHAPA SCHEMAS
# ─────────────────────────────────────────

class ChapaWebhookPayload(BaseModel):
    event: Optional[str] = None
    tx_ref: str
    status: str


# ─────────────────────────────────────────
# WEBSOCKET SCHEMAS
# ─────────────────────────────────────────

class WebSocketMessage(BaseModel):
    type: str
    session_id: str
    status: str
    amount: Optional[float] = None
    worker_name: Optional[str] = None
    payment_reference: Optional[str] = None
    message: str


class TipHistoryItem(BaseModel):
    id: str
    gross_amount: float
    platform_fee: float
    worker_payout: float
    payment_reference: str
    initiated_via: str
    created_at: datetime


class PeriodEarnings(BaseModel):
    total: float
    count: int


class EarningsSummary(BaseModel):
    all_time: PeriodEarnings
    today: PeriodEarnings
    this_week: PeriodEarnings
    this_month: PeriodEarnings
    average_tip: float
    largest_tip: float


class DashboardResponse(BaseModel):
    earnings: EarningsSummary
    recent_tips: list[TipHistoryItem]


class TipHistoryResponse(BaseModel):
    tips: list[TipHistoryItem]
    total: int
    page: int
    page_size: int
    has_more: bool   

class NotificationResponse(BaseModel):
    id: UUID
    worker_id: UUID
    title: str
    message: str
    is_read: bool
    created_at: datetime


class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int
    total: int