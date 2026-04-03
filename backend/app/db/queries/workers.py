from typing import Optional

from psycopg import AsyncConnection


def _row_to_create_worker_dict(row) -> Optional[dict]:
    if row is None:
        return None
    # If we already got a mapping-like row, just use it directly.
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    # Must match the RETURNING column order in create_worker()
    return {
        "id": row[0],
        "name": row[1],
        "phone": row[2],
        "email": row[3],
        "profession": row[4],
        "avatar_url": row[5],
        "qr_code_url": row[6],
        "nfc_enabled": row[7],
        "is_active": row[8],
        "created_at": row[9],
    }


def _row_to_worker_by_phone_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    # Must match the SELECT column order in get_worker_by_phone()
    return {
        "id": row[0],
        "name": row[1],
        "phone": row[2],
        "email": row[3],
        "profession": row[4],
        "avatar_url": row[5],
        "qr_code_url": row[6],
        "nfc_enabled": row[7],
        "is_active": row[8],
        "created_at": row[9],
        "password_hash": row[10],
    }


def _row_to_worker_by_id_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    # Must match the SELECT column order in get_worker_by_id()
    return {
        "id": row[0],
        "name": row[1],
        "phone": row[2],
        "email": row[3],
        "profession": row[4],
        "avatar_url": row[5],
        "qr_code_url": row[6],
        "nfc_enabled": row[7],
        "is_active": row[8],
        "created_at": row[9],
    }


def _row_to_worker_with_payout_dict(row) -> Optional[dict]:
    if row is None:
        return None
    if hasattr(row, "keys") and "id" in row:
        return dict(row)
    return {
        "id": row[0],
        "name": row[1],
        "phone": row[2],
        "email": row[3],
        "profession": row[4],
        "avatar_url": row[5],
        "qr_code_url": row[6],
        "nfc_enabled": row[7],
        "is_active": row[8],
        "created_at": row[9],
        "payout_id": row[10],
        "payout_method": row[11],
        "telebirr_phone": row[12],
        "bank_name": row[13],
        "account_number": row[14],
        "account_name": row[15],
    }


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
        INSERT INTO workers (name, phone, email, password_hash, profession)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id, name, phone, email, profession,
                  avatar_url, qr_code_url, nfc_enabled,
                  is_active, created_at
        """,
        (name, phone, email, password_hash, profession),
    )
    return _row_to_create_worker_dict(await row.fetchone())


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
        (phone,),
    )
    return _row_to_worker_by_phone_dict(await row.fetchone())


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
        (worker_id,),
    )
    return _row_to_worker_by_id_dict(await row.fetchone())


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
            name        = COALESCE(%s, name),
            profession  = COALESCE(%s, profession),
            email       = COALESCE(%s, email)
        WHERE id = %s AND is_active = true
        RETURNING id, name, phone, email, profession,
                  avatar_url, qr_code_url, nfc_enabled,
                  is_active, created_at
        """,
        (name, profession, email, worker_id),
    )
    return _row_to_worker_by_id_dict(await row.fetchone())


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
        (qr_code_url, worker_id),
    )
    return _row_to_worker_by_id_dict(await row.fetchone())

async def get_worker_with_payout(
    db: AsyncConnection,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT
            w.id, w.name, w.phone, w.email,
            w.profession, w.avatar_url, w.qr_code_url,
            w.nfc_enabled, w.is_active, w.created_at,
            pa.id          AS payout_id,
            pa.method      AS payout_method,
            pa.telebirr_phone,
            pa.bank_name,
            pa.account_number,
            pa.account_name
        FROM workers w
        LEFT JOIN payout_accounts pa
            ON pa.worker_id = w.id AND pa.is_active = true
        WHERE w.id = %s AND w.is_active = true
        """,
        (worker_id,)
    )
    return _row_to_worker_with_payout_dict(await row.fetchone())