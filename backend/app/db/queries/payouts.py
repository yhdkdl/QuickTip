from psycopg import AsyncConnection
from typing import Optional


async def create_payout_account(
    db: AsyncConnection,
    worker_id: str,
    method: str,
    telebirr_phone: Optional[str] = None,
    bank_name: Optional[str] = None,
    account_number: Optional[str] = None,
    account_name: Optional[str] = None,
):
    row = await db.execute(
        """
        INSERT INTO payout_accounts
            (worker_id, method, telebirr_phone,
             bank_name, account_number, account_name)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING id, worker_id, method, telebirr_phone,
                  bank_name, account_number, account_name
        """,
        (
            worker_id, method, telebirr_phone,
            bank_name, account_number, account_name
        )
    )
    return await row.fetchone()


async def get_payout_account(
    db: AsyncConnection,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT id, worker_id, method, telebirr_phone,
               bank_name, account_number, account_name
        FROM payout_accounts
        WHERE worker_id = %s AND is_active = true
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (worker_id,)
    )
    return await row.fetchone()


async def create_payout(
    db: AsyncConnection,
    tip_id: str,
    worker_id: str,
    amount: float,
    method: str,
):
    row = await db.execute(
        """
        INSERT INTO payouts
            (tip_id, worker_id, amount, method)
        VALUES (%s, %s, %s, %s)
        RETURNING id, tip_id, worker_id, amount,
                  method, status, attempts, created_at
        """,
        (tip_id, worker_id, amount, method)
    )
    return await row.fetchone()


async def update_payout_attempt(
    db: AsyncConnection,
    payout_id: str,
    status: str,
    chapa_transfer_id: Optional[str] = None,
):
    await db.execute(
        """
        UPDATE payouts
        SET
            status            = %s,
            chapa_transfer_id = COALESCE(%s, chapa_transfer_id),
            attempts          = attempts + 1,
            last_attempt_at   = NOW()
        WHERE id = %s
        """,
        (status, chapa_transfer_id, payout_id)
    )


async def get_payout_by_tip_id(
    db: AsyncConnection,
    tip_id: str,
):
    row = await db.execute(
        """
        SELECT id, tip_id, worker_id, amount,
               method, status, attempts, last_attempt_at
        FROM payouts
        WHERE tip_id = %s
        """,
        (tip_id,)
    )
    return await row.fetchone()


async def get_pending_payouts(
    db: AsyncConnection,
):
    rows = await db.execute(
        """
        SELECT id, tip_id, worker_id, amount,
               method, status, attempts, last_attempt_at
        FROM payouts
        WHERE status = 'pending'
          AND attempts < 3
        ORDER BY created_at ASC
        """,
        ()
    )
    return await rows.fetchall()


async def update_tip_status(
    db: AsyncConnection,
    tip_id: str,
    status: str,
):
    await db.execute(
        """
        UPDATE tip_sessions
        SET status = %s
        WHERE id = (
            SELECT session_id FROM tips WHERE id = %s
        )
        """,
        (status, tip_id)
    )