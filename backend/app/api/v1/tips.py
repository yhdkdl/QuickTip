from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.core.database import get_db
from app.db.queries.tips import (
    create_tip_session,
    get_session_by_id,
    update_session_checkout_id,
)
from app.db.queries.workers import get_worker_by_id
from app.models.schemas import TipInitiate, TipSessionResponse
from app.services.mpesa_service import stk_push

router = APIRouter()


@router.post("/initiate", response_model=TipSessionResponse, status_code=202)
async def initiate_tip(
    payload: TipInitiate,
    db: AsyncConnection = Depends(get_db),
):
    worker = await get_worker_by_id(db, payload.worker_id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found",
        )

    session = await create_tip_session(
        db=db,
        worker_id=payload.worker_id,
        amount=payload.amount,
        customer_phone=payload.customer_phone,
        initiated_via=payload.initiated_via,
    )
    await db.commit()

    try:
        daraja_response = await stk_push(
            phone=payload.customer_phone,
            amount=payload.amount,
            session_id=str(session["id"]),
            worker_name=worker["name"],
        )

        checkout_request_id = daraja_response.get("CheckoutRequestID")
        if checkout_request_id:
            await update_session_checkout_id(
                db=db,
                session_id=str(session["id"]),
                checkout_request_id=checkout_request_id,
            )
            await db.commit()

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Payment gateway error: {str(e)}",
        )

    return TipSessionResponse(
        session_id=str(session["id"]),
        status="pending",
        amount=float(session["amount"]),
        worker_name=worker["name"],
        message="STK Push sent. Please check your phone and enter your M-Pesa PIN.",
    )


@router.get("/session/{session_id}", response_model=TipSessionResponse)
async def get_session_status(
    session_id: str,
    db: AsyncConnection = Depends(get_db),
):
    session = await get_session_by_id(db, session_id)

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    messages = {
        "pending": "Waiting for payment confirmation...",
        "completed": "Payment received. Thank you!",
        "failed": "Payment failed. Please try again.",
        "cancelled": "Payment was cancelled.",
    }

    return TipSessionResponse(
        session_id=str(session["id"]),
        status=session["status"],
        amount=float(session["amount"]),
        worker_name=session["worker_name"],
        message=messages.get(session["status"], "Processing..."),
    )

