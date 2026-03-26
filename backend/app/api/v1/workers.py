from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.api.v1.deps import get_current_worker
from app.core.database import get_db
from app.db.queries.workers import (
    get_worker_by_id,
    update_worker_profile,
    update_worker_qr,
)
from app.models.schemas import (
    PublicWorkerResponse,
    QRCodeResponse,
    WorkerProfileUpdate,
    WorkerResponse,
)
from app.services.qr_service import generate_worker_qr

router = APIRouter()


@router.get("/profile", response_model=WorkerResponse)
async def get_profile(current_worker=Depends(get_current_worker)):
    return WorkerResponse(**dict(current_worker))


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

    updated = await update_worker_profile(
        db=db,
        worker_id=str(current_worker["id"]),
        name=payload.name,
        profession=payload.profession,
        email=payload.email,
    )

    await db.commit()
    return WorkerResponse(**dict(updated))


@router.post("/generate-qr", response_model=QRCodeResponse)
async def generate_qr(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_id = str(current_worker["id"])

    qr_code_url, tip_url = generate_worker_qr(worker_id)

    await update_worker_qr(db=db, worker_id=worker_id, qr_code_url=qr_code_url)
    await db.commit()

    return QRCodeResponse(qr_code_url=qr_code_url, tip_url=tip_url)


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

