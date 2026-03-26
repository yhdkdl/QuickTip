from typing import Optional

from psycopg import AsyncConnection


def _row_to_tip_session_dict(row) -> Optional[dict]:
    if row is None:
        return None

    if hasattr(row, "keys") and "id" in row:
        return dict(row)

    # CREATE:
    # RETURNING id, worker_id, amount, customer_phone,
    #           status, initiated_via, created_at
    #
    # get_session_by_id selects:
    #  ts.id,
    #  ts.worker_id,
    #  ts.amount,
    #  ts.customer_phone,
    #  ts.mpesa_checkout_request_id,
    #  ts.status,
    #  ts.initiated_via,
    #  ts.created_at,
    #  ts.completed_at,
    #  w.name as worker_name
    if len(row) == 7:
        return {
            "id": row[0],
            "worker_id": row[1],
            "amount": row[2],
            "customer_phone": row[3],
            "status": row[4],
            "initiated_via": row[5],
            "created_at": row[6],
        }

    if len(row) >= 10:
        return {
            "id": row[0],
            "worker_id": row[1],
            "amount": row[2],
            "customer_phone": row[3],
            "mpesa_checkout_request_id": row[4],
            "status": row[5],
            "initiated_via": row[6],
            "created_at": row[7],
            "completed_at": row[8],
            "worker_name": row[9],
        }

    # Fallback to a minimal mapping (better than crashing)
    return {"id": row[0]}  # pragma: no cover


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
        (worker_id, amount, customer_phone, initiated_via),
    )
    return _row_to_tip_session_dict(await row.fetchone())


async def update_session_checkout_id(
    db: AsyncConnection,
    session_id: str,
    checkout_request_id: str,
):
    await db.execute(
        """
        UPDATE tip_sessions
        SET mpesa_checkout_request_id = %s
        WHERE id = %s
        """,
        (checkout_request_id, session_id),
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
            ts.mpesa_checkout_request_id,
            ts.status,
            ts.initiated_via,
            ts.created_at,
            ts.completed_at,
            w.name as worker_name
        FROM tip_sessions ts
        JOIN workers w ON w.id = ts.worker_id
        WHERE ts.id = %s
        """,
        (session_id,),
    )
    return _row_to_tip_session_dict(await row.fetchone())


async def get_session_by_checkout_id(
    db: AsyncConnection,
    checkout_request_id: str,
):
    row = await db.execute(
        """
        SELECT id, worker_id, amount, customer_phone,
               mpesa_checkout_request_id, status
        FROM tip_sessions
        WHERE mpesa_checkout_request_id = %s
        """,
        (checkout_request_id,),
    )
    r = await row.fetchone()
    if r is None:
        return None
    if hasattr(r, "keys") and "id" in r:
        return dict(r)
    return {
        "id": r[0],
        "worker_id": r[1],
        "amount": r[2],
        "customer_phone": r[3],
        "mpesa_checkout_request_id": r[4],
        "status": r[5],
    }

