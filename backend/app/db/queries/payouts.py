from psycopg import AsyncConnection
from typing import Optional


def _row_to_payout_account_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "worker_id": row[1],
        "method": row[2],
        "telebirr_phone": row[3],
        "bank_name": row[4],
        "account_number": row[5],
        "account_name": row[6],
    }


def _row_to_payout_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "tip_id": row[1],
        "worker_id": row[2],
        "amount": row[3],
        "method": row[4],
        "status": row[5],
        "attempts": row[6],
        "created_at": row[7],
    }


def _row_to_payout_full_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "tip_id": row[1],
        "worker_id": row[2],
        "amount": row[3],
        "method": row[4],
        "status": row[5],
        "attempts": row[6],
        "chapa_transfer_id": row[7],
        "failure_reason": row[8],
        "created_at": row[9],
    }


def _row_to_pending_payout_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "tip_id": row[1],
        "worker_id": row[2],
        "amount": row[3],
        "method": row[4],
        "status": row[5],
        "attempts": row[6],
        "failure_reason": row[7],
        "created_at": row[8],
        "telebirr_phone": row[9],
        "bank_name": row[10],
        "account_number": row[11],
        "account_name": row[12],
    }
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
    return _row_to_payout_account_dict(await row.fetchone())


async def get_payout_account_by_worker(
    db: AsyncConnection,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT id, worker_id, method, telebirr_phone,
               bank_name, account_number, account_name
        FROM payout_accounts
        WHERE worker_id = %s AND is_active = true
        """,
        (worker_id,)
    )
    return _row_to_payout_account_dict(await row.fetchone())


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
    return _row_to_payout_dict(await row.fetchone())


async def get_payout_by_tip_id(
    db: AsyncConnection,
    tip_id: str,
):
    row = await db.execute(
        """
        SELECT id, tip_id, worker_id, amount, method,
               status, attempts, chapa_transfer_id,
               failure_reason, created_at
        FROM payouts
        WHERE tip_id = %s
        """,
        (tip_id,)
    )
    return _row_to_payout_full_dict(await row.fetchone())


async def update_payout_attempt(
    db: AsyncConnection,
    payout_id: str,
    status: str,
    attempts: int,
    chapa_transfer_id: Optional[str] = None,
    failure_reason: Optional[str] = None,
):
    await db.execute(
        """
        UPDATE payouts
        SET
            status             = %s,
            attempts           = %s,
            chapa_transfer_id  = COALESCE(%s, chapa_transfer_id),
            failure_reason     = COALESCE(%s, failure_reason),
            last_attempt_at    = NOW()
        WHERE id = %s
        """,
        (status, attempts, chapa_transfer_id, failure_reason, payout_id)
    )


async def get_pending_payouts(db: AsyncConnection):
    rows = await db.execute(
        """
        SELECT
            p.id, p.tip_id, p.worker_id, p.amount,
            p.method, p.status, p.attempts,
            p.failure_reason, p.created_at,
            pa.telebirr_phone, pa.bank_name,
            pa.account_number, pa.account_name
        FROM payouts p
        JOIN payout_accounts pa ON pa.worker_id = p.worker_id
            AND pa.is_active = true
        WHERE p.status = 'pending'
          AND p.attempts < 3
        """,
        ()
    )
    return [_row_to_pending_payout_dict(r) for r in await rows.fetchall()]