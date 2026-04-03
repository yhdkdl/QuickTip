import asyncio
from psycopg_pool import AsyncConnectionPool
from app.services.chapa_service import (
    transfer_to_telebirr,
    transfer_to_bank,
    refund_payment,
)
from app.db.queries.payouts import (
    get_payout_account,
    update_payout_attempt,
    get_payout_by_tip_id,
)
from app.db.queries.tips import (
    update_session_status,
    create_notification,
)

MAX_ATTEMPTS = 3
RETRY_DELAY_SECONDS = 180


async def attempt_payout(
    pool: AsyncConnectionPool,
    payout_id: str,
    tip_id: str,
    worker_id: str,
    amount: float,
    tx_ref: str,
    session_id: str,
):
    async with pool.connection() as db:
        payout_account = await get_payout_account(db, worker_id)

        if not payout_account:
            await update_payout_attempt(db, payout_id, "failed")
            await db.commit()
            return False

        try:
            if payout_account["method"] == "telebirr":
                response = await transfer_to_telebirr(
                    amount=amount,
                    phone=payout_account["telebirr_phone"],
                    payout_id=payout_id,
                    worker_name=payout_account["account_name"]
                    or "Worker",
                )
            else:
                response = await transfer_to_bank(
                    amount=amount,
                    account_number=payout_account["account_number"],
                    account_name=payout_account["account_name"],
                    bank_name=payout_account["bank_name"],
                    payout_id=payout_id,
                )

            transfer_id = (
                response.get("data", {}).get("transfer_id")
                or response.get("data", {}).get("id")
            )

            await update_payout_attempt(
                db, payout_id, "completed", transfer_id
            )

            await create_notification(
                db=db,
                worker_id=worker_id,
                title="Payout Sent! 💰",
                message=(
                    f"ETB {amount:.0f} has been sent to your "
                    f"{payout_account['method']} account."
                ),
            )

            await db.commit()
            return True

        except Exception:
            await update_payout_attempt(db, payout_id, "failed")
            await db.commit()
            return False


async def payout_with_retry(
    pool: AsyncConnectionPool,
    payout_id: str,
    tip_id: str,
    worker_id: str,
    amount: float,
    tx_ref: str,
    session_id: str,
):
    for attempt in range(MAX_ATTEMPTS):
        success = await attempt_payout(
            pool=pool,
            payout_id=payout_id,
            tip_id=tip_id,
            worker_id=worker_id,
            amount=amount,
            tx_ref=tx_ref,
            session_id=session_id,
        )

        if success:
            return

        if attempt < MAX_ATTEMPTS - 1:
            await asyncio.sleep(RETRY_DELAY_SECONDS)

    await handle_payout_exhausted(
        pool=pool,
        payout_id=payout_id,
        tip_id=tip_id,
        worker_id=worker_id,
        amount=amount,
        tx_ref=tx_ref,
        session_id=session_id,
    )


async def handle_payout_exhausted(
    pool: AsyncConnectionPool,
    payout_id: str,
    tip_id: str,
    worker_id: str,
    amount: float,
    tx_ref: str,
    session_id: str,
):
    async with pool.connection() as db:
        try:
            await refund_payment(tx_ref=tx_ref, amount=amount)

            await update_payout_attempt(db, payout_id, "reversed")
            await update_session_status(db, session_id, "cancelled")

            await create_notification(
                db=db,
                worker_id=worker_id,
                title="Payout Failed ⚠️",
                message=(
                    "We could not send your tip payout after 3 attempts. "
                    "The customer has been refunded. "
                    "Please update your payout details."
                ),
            )

            await db.commit()

        except Exception:
            await update_payout_attempt(db, payout_id, "reversed")
            await db.commit()