from psycopg import AsyncConnection
from typing import Optional


async def create_worker(
    db: AsyncConnection,
    name: str,
    phone: str,
    password_hash: str,
    email: Optional[str] = None,
    profession: Optional[str] = None,
):
    row = await db.execute(
        """
        INSERT INTO workers
            (name, phone, email, password_hash, profession)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id, name, phone, email, profession,
                  avatar_url, qr_code_url, nfc_enabled,
                  is_active, created_at
        """,
        (name, phone, email, password_hash, profession)
    )
    return await row.fetchone()


async def get_worker_by_phone(
    db: AsyncConnection,
    phone: str,
):
    row = await db.execute(
        """
        SELECT id, name, phone, email, profession,
               avatar_url, qr_code_url, nfc_enabled,
               is_active, created_at, password_hash
        FROM workers
        WHERE phone = %s AND is_active = true
        """,
        (phone,)
    )
    return await row.fetchone()


async def get_worker_by_id(
    db: AsyncConnection,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT id, name, phone, email, profession,
               avatar_url, qr_code_url, nfc_enabled,
               is_active, created_at
        FROM workers
        WHERE id = %s AND is_active = true
        """,
        (worker_id,)
    )
    return await row.fetchone()


async def get_worker_with_payout(
    db: AsyncConnection,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT
            w.id, w.name, w.phone, w.email, w.profession,
            w.avatar_url, w.qr_code_url, w.nfc_enabled,
            w.is_active, w.created_at,
            pa.id         AS payout_id,
            pa.method     AS payout_method,
            pa.telebirr_phone,
            pa.bank_name,
            pa.account_number,
            pa.account_name
        FROM workers w
        LEFT JOIN payout_accounts pa
            ON pa.worker_id = w.id AND pa.is_active = true
        WHERE w.id = %s AND w.is_active = true
        ORDER BY pa.created_at DESC
        LIMIT 1
        """,
        (worker_id,)
    )
    return await row.fetchone()


async def update_worker_profile(
    db: AsyncConnection,
    worker_id: str,
    name: Optional[str] = None,
    profession: Optional[str] = None,
    email: Optional[str] = None,
):
    row = await db.execute(
        """
        UPDATE workers
        SET
            name       = COALESCE(%s, name),
            profession = COALESCE(%s, profession),
            email      = COALESCE(%s, email)
        WHERE id = %s AND is_active = true
        RETURNING id, name, phone, email, profession,
                  avatar_url, qr_code_url, nfc_enabled,
                  is_active, created_at
        """,
        (name, profession, email, worker_id)
    )
    return await row.fetchone()


async def update_worker_qr(
    db: AsyncConnection,
    worker_id: str,
    qr_code_url: str,
):
    row = await db.execute(
        """
        UPDATE workers
        SET qr_code_url = %s
        WHERE id = %s AND is_active = true
        RETURNING id, name, phone, email, profession,
                  avatar_url, qr_code_url, nfc_enabled,
                  is_active, created_at
        """,
        (qr_code_url, worker_id)
    )
    return await row.fetchone()