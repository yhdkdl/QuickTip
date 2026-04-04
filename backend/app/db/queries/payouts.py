from psycopg import AsyncConnection
from typing import Optional


async def create_payout_account(
    db: AsyncConnection,
    worker_id: str,
    method: str,
    is_default: bool = False,
    telebirr_phone: Optional[str] = None,
    bank_name: Optional[str] = None,
    account_number: Optional[str] = None,
    account_name: Optional[str] = None,
):
    row = await db.execute(
        """
        INSERT INTO payout_accounts
            (worker_id, method, telebirr_phone,
             bank_name, account_number, account_name,
             is_default)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id, worker_id, method, telebirr_phone,
                  bank_name, account_number, account_name,
                  is_default, created_at
        """,
        (
            worker_id, method, telebirr_phone,
            bank_name, account_number, account_name,
            is_default,
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
               bank_name, account_number, account_name,
               is_default, created_at
        FROM payout_accounts
        WHERE worker_id = %s
          AND is_default = true
          AND is_active = true
        LIMIT 1
        """,
        (worker_id,)
    )
    return await row.fetchone()


async def get_all_payout_accounts(
    db: AsyncConnection,
    worker_id: str,
):
    rows = await db.execute(
        """
        SELECT id, worker_id, method, telebirr_phone,
               bank_name, account_number, account_name,
               is_default, created_at
        FROM payout_accounts
        WHERE worker_id = %s
          AND is_active = true
        ORDER BY is_default DESC, created_at ASC
        """,
        (worker_id,)
    )
    return await rows.fetchall()


async def get_payout_account_by_id(
    db: AsyncConnection,
    account_id: str,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT id, worker_id, method, telebirr_phone,
               bank_name, account_number, account_name,
               is_default, created_at
        FROM payout_accounts
        WHERE id = %s
          AND worker_id = %s
          AND is_active = true
        """,
        (account_id, worker_id)
    )
    return await row.fetchone()


async def set_default_payout_account(
    db: AsyncConnection,
    account_id: str,
    worker_id: str,
):
    await db.execute(
        """
        UPDATE payout_accounts
        SET is_default = false
        WHERE worker_id = %s
          AND is_active = true
          AND is_default = true
        """,
        (worker_id,)
    )

    row = await db.execute(
        """
        UPDATE payout_accounts
        SET is_default = true
        WHERE id = %s
          AND worker_id = %s
          AND is_active = true
        RETURNING id, worker_id, method, telebirr_phone,
                  bank_name, account_number, account_name,
                  is_default, created_at
        """,
        (account_id, worker_id)
    )
    return await row.fetchone()


async def deactivate_payout_account(
    db: AsyncConnection,
    account_id: str,
    worker_id: str,
):
    await db.execute(
        """
        UPDATE payout_accounts
        SET is_active = false
        WHERE id = %s
          AND worker_id = %s
          AND is_default = false
        """,
        (account_id, worker_id)
    )


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