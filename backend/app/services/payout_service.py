import asyncio
from app.services.chapa_service import (
    transfer_to_telebirr,
    transfer_to_bank,
    refund_payment,
)
from app.db.queries.payouts import (
    update_payout_attempt,
    get_payout_by_tip_id,
)
from app.db.queries.tips import (
    update_session_status,
    create_notification,
)
from app.services.websocket_manager import manager
from app.core.database import pool

MAX_ATTEMPTS = 3
RETRY_DELAYS = [180, 300]


async def execute_transfer(
    payout_account: dict,
    amount: float,
    reference: str,
    worker_name: str,
) -> dict:
    method = payout_account["payout_method"]

    if method == "telebirr":
        return await transfer_to_telebirr(
            amount=amount,
            phone=payout_account["telebirr_phone"],
            reference=reference,
            worker_name=worker_name,
        )
    else:
        return await transfer_to_bank(
            amount=amount,
            account_number=payout_account["account_number"],
            account_name=payout_account["account_name"],
            bank_name=payout_account["bank_name"],
            reference=reference,
        )


async def attempt_payout(
    payout_id: str,
    tip_id: str,
    worker_id: str,
    amount: float,
    payout_account: dict,
    worker_name: str,
    session_id: str,
    tx_ref: str,
    attempt_number: int,
):
    async with pool.connection() as db:
        try:
            reference = f"payout-{payout_id}-attempt-{attempt_number}"
            result = await execute_transfer(
                payout_account=payout_account,
                amount=amount,
                reference=reference,
                worker_name=worker_name,
            )

            transfer_id = (
                result.get("data", {}).get("transfer_id", reference)
            )

            await update_payout_attempt(
                db=db,
                payout_id=payout_id,
                status="completed",
                attempts=attempt_number,
                chapa_transfer_id=transfer_id,
            )

            await create_notification(
                db=db,
                worker_id=worker_id,
                title="Tip Payout Sent! 💸",
                message=(
                    f"ETB {amount:.0f} has been sent to your "
                    f"{payout_account['payout_method']} account."
                ),
            )

            await db.commit()

            await manager.send(session_id, {
                "type": "payout_update",
                "session_id": session_id,
                "status": "payout_completed",
                "amount": amount,
                "worker_name": worker_name,
                "message": "Your tip payout has been sent.",
            })

        except Exception as e:
            failure_reason = str(e)

            if attempt_number >= MAX_ATTEMPTS:
                await _handle_final_failure(
                    db=db,
                    payout_id=payout_id,
                    tip_id=tip_id,
                    worker_id=worker_id,
                    amount=amount,
                    session_id=session_id,
                    tx_ref=tx_ref,
                    failure_reason=failure_reason,
                    attempt_number=attempt_number,
                )
            else:
                await update_payout_attempt(
                    db=db,
                    payout_id=payout_id,
                    status="pending",
                    attempts=attempt_number,
                    failure_reason=failure_reason,
                )
                await db.commit()

                delay = RETRY_DELAYS[attempt_number - 1]
                asyncio.create_task(
                    _schedule_retry(
                        delay=delay,
                        payout_id=payout_id,
                        tip_id=tip_id,
                        worker_id=worker_id,
                        amount=amount,
                        payout_account=payout_account,
                        worker_name=worker_name,
                        session_id=session_id,
                        tx_ref=tx_ref,
                        attempt_number=attempt_number + 1,
                    )
                )


async def _schedule_retry(
    delay: int,
    **kwargs,
):
    await asyncio.sleep(delay)
    await attempt_payout(**kwargs)


async def _handle_final_failure(
    db,
    payout_id: str,
    tip_id: str,
    worker_id: str,
    amount: float,
    session_id: str,
    tx_ref: str,
    failure_reason: str,
    attempt_number: int,
):
    await update_payout_attempt(
        db=db,
        payout_id=payout_id,
        status="reversed",
        attempts=attempt_number,
        failure_reason=failure_reason,
    )

    try:
        await refund_payment(
            tx_ref=tx_ref,
            amount=amount,
        )
    except Exception as refund_error:
        pass

    await create_notification(
        db=db,
        worker_id=worker_id,
        title="Payout Failed ⚠️",
        message=(
            "We could not send your tip payout after 3 attempts. "
            "The customer has been refunded. "
            "Please update your payout account details."
        ),
    )

    await db.commit()

    await manager.send(session_id, {
        "type": "payout_update",
        "session_id": session_id,
        "status": "payout_reversed",
        "amount": amount,
        "worker_name": "",
        "message": (
            "Payment reversed. Payout could not be completed. "
            "Please try again later."
        ),
    })