from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.core.database import get_db
from app.models.schemas import (
    WorkerRegister,
    WorkerLogin,
    TokenResponse,
    WorkerResponse,
    PayoutAccountResponse,
)
from app.db.queries.workers import (
    create_worker,
    get_worker_by_phone,
    get_worker_with_payout,
)
from app.db.queries.payouts import create_payout_account
from app.services.auth_service import (
    hash_password,
    verify_password,
    create_access_token,
)
from app.api.v1.deps import get_current_worker

router = APIRouter()


def build_worker_response(row) -> WorkerResponse:
    data = dict(row)

    payout = None
    if data.get("payout_id"):
        payout = PayoutAccountResponse(
            id=data["payout_id"],
            method=data["payout_method"],
            telebirr_phone=data.get("telebirr_phone"),
            bank_name=data.get("bank_name"),
            account_number=data.get("account_number"),
            account_name=data.get("account_name"),
        )

    return WorkerResponse(
        id=data["id"],
        name=data["name"],
        phone=data["phone"],
        email=data.get("email"),
        profession=data.get("profession"),
        avatar_url=data.get("avatar_url"),
        qr_code_url=data.get("qr_code_url"),
        nfc_enabled=data["nfc_enabled"],
        is_active=data["is_active"],
        created_at=data["created_at"],
        payout_account=payout,
    )


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=201,
)
async def register(
    payload: WorkerRegister,
    db: AsyncConnection = Depends(get_db),
):
    existing = await get_worker_by_phone(db, payload.phone)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A worker with this phone number already exists",
        )

    password_hash = hash_password(payload.password)

    worker = await create_worker(
        db=db,
        name=payload.name,
        phone=payload.phone,
        password_hash=password_hash,
        email=payload.email,
        profession=payload.profession,
    )

    await create_payout_account(
        db=db,
        worker_id=str(worker["id"]),
        method=payload.payout.method,
        telebirr_phone=payload.payout.telebirr_phone,
        bank_name=payload.payout.bank_name,
        account_number=payload.payout.account_number,
        account_name=payload.payout.account_name,
    )

    await db.commit()

    full_worker = await get_worker_with_payout(db, str(worker["id"]))
    token = create_access_token(str(worker["id"]))

    return TokenResponse(
        access_token=token,
        worker=build_worker_response(full_worker),
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    payload: WorkerLogin,
    db: AsyncConnection = Depends(get_db),
):
    worker = await get_worker_by_phone(db, payload.phone)

    if not worker or not verify_password(
        payload.password, worker["password_hash"]
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone number or password",
        )

    full_worker = await get_worker_with_payout(
        db, str(worker["id"])
    )
    token = create_access_token(str(worker["id"]))

    return TokenResponse(
        access_token=token,
        worker=build_worker_response(full_worker),
    )


@router.get("/me", response_model=WorkerResponse)
async def get_me(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    full_worker = await get_worker_with_payout(
        db, str(current_worker["id"])
    )
    return build_worker_response(full_worker)