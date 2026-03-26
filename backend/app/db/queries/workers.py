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
