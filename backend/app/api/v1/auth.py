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
from app.db.queries.payouts import (
    create_payout_account,
    get_payout_account_by_worker,
)
from app.services.auth_service import (
    hash_password,
    verify_password,
    create_access_token,
)
from app.api.v1.deps import get_current_worker

router = APIRouter()


def build_worker_response(worker_row, payout_row=None) -> WorkerResponse:
    payout = None
    if payout_row:
        payout = PayoutAccountResponse(
            id=payout_row["id"],
            method=payout_row["method"],
            telebirr_phone=payout_row.get("telebirr_phone"),
            bank_name=payout_row.get("bank_name"),
            account_number=payout_row.get("account_number"),
            account_name=payout_row.get("account_name"),
        )

    return WorkerResponse(
        id=worker_row["id"],
        name=worker_row["name"],
        phone=worker_row["phone"],
        email=worker_row.get("email"),
        profession=worker_row.get("profession"),
        avatar_url=worker_row.get("avatar_url"),
        qr_code_url=worker_row.get("qr_code_url"),
        nfc_enabled=worker_row["nfc_enabled"],
        is_active=worker_row["is_active"],
        created_at=worker_row["created_at"],
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

    payout = await create_payout_account(
        db=db,
        worker_id=str(worker["id"]),
        method=payload.payout_method,
        telebirr_phone=payload.telebirr_phone,
        bank_name=payload.bank_name,
        account_number=payload.account_number,
        account_name=payload.account_name,
    )

    await db.commit()

    token = create_access_token(str(worker["id"]))

    return TokenResponse(
        access_token=token,
        worker=build_worker_response(worker, payout),
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

    worker_with_payout = await get_worker_with_payout(
        db, str(worker["id"])
    )

    payout = None
    if worker_with_payout and worker_with_payout["payout_id"]:
        payout_data = {
            "id": worker_with_payout["payout_id"],
            "method": worker_with_payout["payout_method"],
            "telebirr_phone": worker_with_payout.get("telebirr_phone"),
            "bank_name": worker_with_payout.get("bank_name"),
            "account_number": worker_with_payout.get("account_number"),
            "account_name": worker_with_payout.get("account_name"),
        }
    else:
        payout_data = None

    token = create_access_token(str(worker["id"]))

    return TokenResponse(
        access_token=token,
        worker=build_worker_response(worker_with_payout, payout_data),
    )


@router.get("/me", response_model=WorkerResponse)
async def get_me(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_with_payout = await get_worker_with_payout(
        db, str(current_worker["id"])
    )

    payout_data = None
    if worker_with_payout and worker_with_payout.get("payout_id"):
        payout_data = {
            "id": worker_with_payout["payout_id"],
            "method": worker_with_payout["payout_method"],
            "telebirr_phone": worker_with_payout.get("telebirr_phone"),
            "bank_name": worker_with_payout.get("bank_name"),
            "account_number": worker_with_payout.get("account_number"),
            "account_name": worker_with_payout.get("account_name"),
        }

    return build_worker_response(worker_with_payout, payout_data)