from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.core.database import get_db
from app.models.schemas import (
    WorkerResponse,
    WorkerProfileUpdate,
    PublicWorkerResponse,
    QRCodeResponse,
    PayoutAccountCreate,
    PayoutAccountResponse,
    PayoutAccountListResponse,
)
from app.db.queries.workers import (
    update_worker_profile,
    update_worker_qr,
    get_worker_by_id,
    get_worker_with_payout,
)
from app.db.queries.payouts import (
    create_payout_account,
    get_all_payout_accounts,
    get_payout_account_by_id,
    set_default_payout_account,
    deactivate_payout_account,
)
from app.services.qr_service import generate_worker_qr
from app.api.v1.auth import build_worker_response
from app.api.v1.deps import get_current_worker

router = APIRouter()


@router.get("/profile", response_model=WorkerResponse)
async def get_profile(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    full_worker = await get_worker_with_payout(
        db, str(current_worker["id"])
    )
    return build_worker_response(full_worker)


@router.put("/profile", response_model=WorkerResponse)
async def update_profile(
    payload: WorkerProfileUpdate,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    if not any([payload.name, payload.profession, payload.email]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one field must be provided",
        )

    await update_worker_profile(
        db=db,
        worker_id=str(current_worker["id"]),
        name=payload.name,
        profession=payload.profession,
        email=payload.email,
    )

    await db.commit()

    full_worker = await get_worker_with_payout(
        db, str(current_worker["id"])
    )
    return build_worker_response(full_worker)


@router.post("/generate-qr", response_model=QRCodeResponse)
async def generate_qr(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_id = str(current_worker["id"])
    qr_code_url, tip_url = generate_worker_qr(worker_id)

    await update_worker_qr(
        db=db,
        worker_id=worker_id,
        qr_code_url=qr_code_url,
    )
    await db.commit()

    return QRCodeResponse(
        qr_code_url=qr_code_url,
        tip_url=tip_url,
    )


@router.get(
    "/payout-accounts",
    response_model=PayoutAccountListResponse,
)
async def list_payout_accounts(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    accounts = await get_all_payout_accounts(
        db, str(current_worker["id"])
    )

    return PayoutAccountListResponse(
        accounts=[
            PayoutAccountResponse(**dict(a)) for a in accounts
        ],
        total=len(accounts),
    )


@router.post(
    "/payout-accounts",
    response_model=PayoutAccountResponse,
    status_code=201,
)
async def add_payout_account(
    payload: PayoutAccountCreate,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    account = await create_payout_account(
        db=db,
        worker_id=str(current_worker["id"]),
        method=payload.method,
        is_default=False,
        telebirr_phone=payload.telebirr_phone,
        bank_name=payload.bank_name,
        account_number=payload.account_number,
        account_name=payload.account_name,
    )

    await db.commit()

    return PayoutAccountResponse(**dict(account))


@router.put(
    "/payout-accounts/{account_id}/default",
    response_model=PayoutAccountResponse,
)
async def change_default_account(
    account_id: str,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    existing = await get_payout_account_by_id(
        db, account_id, str(current_worker["id"])
    )

    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payout account not found",
        )

    if existing["is_default"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account is already the default",
        )

    updated = await set_default_payout_account(
        db=db,
        account_id=account_id,
        worker_id=str(current_worker["id"]),
    )

    await db.commit()

    return PayoutAccountResponse(**dict(updated))


@router.delete(
    "/payout-accounts/{account_id}",
    status_code=204,
)
async def remove_payout_account(
    account_id: str,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    existing = await get_payout_account_by_id(
        db, account_id, str(current_worker["id"])
    )

    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payout account not found",
        )

    if existing["is_default"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Cannot remove your default payout account. "
                "Set another account as default first."
            ),
        )

    await deactivate_payout_account(
        db=db,
        account_id=account_id,
        worker_id=str(current_worker["id"]),
    )

    await db.commit()


@router.get("/{worker_id}", response_model=PublicWorkerResponse)
async def get_public_profile(
    worker_id: str,
    db: AsyncConnection = Depends(get_db),
):
    worker = await get_worker_by_id(db, worker_id)

    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found",
        )

    return PublicWorkerResponse(**dict(worker))