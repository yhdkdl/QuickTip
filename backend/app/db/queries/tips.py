from psycopg import AsyncConnection
from app.core.config import get_settings

settings = get_settings()


def _row_to_tip_session_dict(row):
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "worker_id": row[1],
        "amount": row[2],
        "customer_phone": row[3],
        "status": row[4],
        "initiated_via": row[5],
        "created_at": row[6],
    }


def _row_to_session_with_worker_dict(row):
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "worker_id": row[1],
        "amount": row[2],
        "customer_phone": row[3],
        "payment_checkout_id": row[4],
        "status": row[5],
        "initiated_via": row[6],
        "created_at": row[7],
        "completed_at": row[8],
        "worker_name": row[9],
    }


def _row_to_session_short_dict(row):
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "worker_id": row[1],
        "amount": row[2],
        "customer_phone": row[3],
        "payment_checkout_id": row[4],
        "status": row[5],
    }


def _row_to_tip_dict(row):
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "gross_amount": row[1],
        "platform_fee": row[2],
        "worker_payout": row[3],
        "payment_reference": row[4],
    }


async def create_tip_session(
    db: AsyncConnection,
    worker_id: str,
    amount: float,
    customer_phone: str,
    initiated_via: str = "qr",
):
    row = await db.execute(
        """
        INSERT INTO tip_sessions
            (worker_id, amount, customer_phone, initiated_via)
        VALUES (%s, %s, %s, %s)
        RETURNING id, worker_id, amount, customer_phone,
                  status, initiated_via, created_at
        """,
        (worker_id, amount, customer_phone, initiated_via)
    )
    return _row_to_tip_session_dict(await row.fetchone())


async def update_session_checkout_id(
    db: AsyncConnection,
    session_id: str,
    checkout_id: str,
):
    await db.execute(
        """
        UPDATE tip_sessions
        SET payment_checkout_id = %s
        WHERE id = %s
        """,
        (checkout_id, session_id)
    )


async def get_session_by_id(
    db: AsyncConnection,
    session_id: str,
):
    row = await db.execute(
        """
        SELECT
            ts.id,
            ts.worker_id,
            ts.amount,
            ts.customer_phone,
            ts.payment_checkout_id,
            ts.status,
            ts.initiated_via,
            ts.created_at,
            ts.completed_at,
            w.name as worker_name
        FROM tip_sessions ts
        JOIN workers w ON w.id = ts.worker_id
        WHERE ts.id = %s
        """,
        (session_id,)
    )
    return _row_to_session_with_worker_dict(await row.fetchone())


async def get_session_by_tx_ref(
    db: AsyncConnection,
    tx_ref: str,
):
    session_id = tx_ref.replace("quicktip-", "")
    row = await db.execute(
        """
        SELECT id, worker_id, amount, customer_phone,
               payment_checkout_id, status
        FROM tip_sessions
        WHERE id = %s
        """,
        (session_id,)
    )
    return _row_to_session_short_dict(await row.fetchone())


async def update_session_status(
    db: AsyncConnection,
    session_id: str,
    status: str,
):
    await db.execute(
        """
        UPDATE tip_sessions
        SET
            status       = %s,
            completed_at = NOW()
        WHERE id = %s
        """,
        (status, session_id)
    )


async def create_confirmed_tip(
    db: AsyncConnection,
    session_id: str,
    worker_id: str,
    gross_amount: float,
    payment_reference: str,
):
    fee_percent = settings.platform_fee_percent
    platform_fee = round(gross_amount * fee_percent / 100, 2)
    worker_payout = round(gross_amount - platform_fee, 2)

    row = await db.execute(
        """
        INSERT INTO tips
            (session_id, worker_id, gross_amount,
             platform_fee, worker_payout, payment_reference)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING id, gross_amount, platform_fee,
                  worker_payout, payment_reference
        """,
        (session_id, worker_id, gross_amount,
         platform_fee, worker_payout, payment_reference)
    )
    return _row_to_tip_dict(await row.fetchone())


async def create_notification(
    db: AsyncConnection,
    worker_id: str,
    title: str,
    message: str,
):
    await db.execute(
        """
        INSERT INTO notifications (worker_id, title, message)
        VALUES (%s, %s, %s)
        """,
        (worker_id, title, message)
    )