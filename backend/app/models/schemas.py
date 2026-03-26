from datetime import datetime
import re
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, field_validator


class WorkerRegister(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    password: str
    profession: Optional[str] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Kenyan Safaricom format: 2547XXXXXXXX or 2541XXXXXXXX
        pattern = r"^2547\d{8}$|^2541\d{8}$"
        if not re.match(pattern, v):
            raise ValueError("Phone must be in format 2547XXXXXXXX or 2541XXXXXXXX")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        # bcrypt silently fails if the password is longer than 72 bytes (UTF-8).
        # Enforce this at the API boundary so /register returns a 422 instead of 500.
        if len(v.encode("utf-8")) > 72:
            raise ValueError("Password must be at most 72 UTF-8 bytes")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
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
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
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
