from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.api.v1.deps import get_current_worker
from app.core.database import get_db
from app.db.queries.workers import create_worker, get_worker_by_phone
from app.models.schemas import (
    TokenResponse,
    WorkerLogin,
    WorkerRegister,
    WorkerResponse,
)
from app.services.auth_service import (
    create_access_token,
    hash_password,
    verify_password,
)

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
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

    await db.commit()

    token = create_access_token(str(worker["id"]))

    return TokenResponse(
        access_token=token,
        worker=WorkerResponse(**dict(worker)),
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    payload: WorkerLogin,
    db: AsyncConnection = Depends(get_db),
):
    worker = await get_worker_by_phone(db, payload.phone)

    if not worker or not verify_password(payload.password, worker["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone number or password",
        )

    token = create_access_token(str(worker["id"]))

    worker_data = dict(worker)
    worker_data.pop("password_hash")

    return TokenResponse(
        access_token=token,
        worker=WorkerResponse(**worker_data),
    )


@router.get("/me", response_model=WorkerResponse)
async def get_me(current_worker=Depends(get_current_worker)):
    return WorkerResponse(**dict(current_worker))
