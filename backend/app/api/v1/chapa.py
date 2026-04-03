from fastapi import APIRouter, Depends, Request, HTTPException
from psycopg import AsyncConnection

from app.core.database import get_db
from app.db.queries.tips import (
    get_session_by_tx_ref,
    update_session_status,
    create_confirmed_tip,
    create_notification,
)
from app.db.queries.workers import get_worker_by_id
from app.services.chapa_service import verify_payment
from app.services.websocket_manager import manager

router = APIRouter()


@router.post("/webhook")
async def chapa_webhook(
    request: Request,
    db: AsyncConnection = Depends(get_db),
):
    try:
        body = await request.json()
    except Exception:
        return {"status": "accepted"}

    tx_ref = body.get("tx_ref")
    event = body.get("event", "")
    status = body.get("status", "")

    if not tx_ref:
        return {"status": "accepted"}

    if event != "charge.success" and status != "success":
        return {"status": "accepted"}

    session = await get_session_by_tx_ref(db, tx_ref)

    if not session:
        return {"status": "accepted"}

    if session["status"] != "pending":
        return {"status": "accepted"}

    session_id = str(session["id"])
    worker_id = str(session["worker_id"])
    amount = float(session["amount"])

    try:
        verification = await verify_payment(tx_ref)
        verified_status = verification.get("data", {}).get("status", "")

        if verified_status != "success":
            await update_session_status(db, session_id, "failed")
            await db.commit()
            await manager.send(session_id, {
                "type": "payment_update",
                "session_id": session_id,
                "status": "failed",
                "amount": amount,
                "worker_name": "",
                "payment_reference": None,
                "message": "Payment verification failed.",
            })
            return {"status": "accepted"}

        payment_reference = (
            verification.get("data", {}).get("reference", tx_ref)
        )

    except Exception:
        return {"status": "accepted"}

    tip = await create_confirmed_tip(
        db=db,
        session_id=session_id,
        worker_id=worker_id,
        gross_amount=amount,
        payment_reference=payment_reference,
    )

    await update_session_status(db, session_id, "completed")

    worker = await get_worker_by_id(db, worker_id)
    worker_name = worker["name"] if worker else "Worker"

    await create_notification(
        db=db,
        worker_id=worker_id,
        title="New Tip Received! 🎉",
        message=(
            f"You received an ETB {amount:.0f} tip. "
            f"Reference: {payment_reference}"
        ),
    )

    await db.commit()

    await manager.send(session_id, {
        "type": "payment_update",
        "session_id": session_id,
        "status": "completed",
        "amount": amount,
        "worker_name": worker_name,
        "payment_reference": payment_reference,
        "message": "Payment confirmed! Thank you for your tip.",
    })

    return {"status": "accepted"}