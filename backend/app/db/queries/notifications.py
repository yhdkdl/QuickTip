from psycopg import AsyncConnection


async def get_worker_notifications(
    db: AsyncConnection,
    worker_id: str,
    limit: int = 50,
    offset: int = 0,
):
    rows = await db.execute(
        """
        SELECT id, worker_id, title, message,
               is_read, created_at
        FROM notifications
        WHERE worker_id = %s
        ORDER BY created_at DESC
        LIMIT %s OFFSET %s
        """,
        (worker_id, limit, offset)
    )
    return await rows.fetchall()


async def get_unread_count(
    db: AsyncConnection,
    worker_id: str,
) -> int:
    row = await db.execute(
        """
        SELECT COUNT(*) as count
        FROM notifications
        WHERE worker_id = %s AND is_read = false
        """,
        (worker_id,)
    )
    result = await row.fetchone()
    return result["count"] if result else 0


async def mark_notification_read(
    db: AsyncConnection,
    notification_id: str,
    worker_id: str,
):
    row = await db.execute(
        """
        UPDATE notifications
        SET is_read = true
        WHERE id = %s AND worker_id = %s
        RETURNING id, worker_id, title,
                  message, is_read, created_at
        """,
        (notification_id, worker_id)
    )
    return await row.fetchone()


async def mark_all_read(
    db: AsyncConnection,
    worker_id: str,
):
    await db.execute(
        """
        UPDATE notifications
        SET is_read = true
        WHERE worker_id = %s AND is_read = false
        """,
        (worker_id,)
    )


async def delete_notification(
    db: AsyncConnection,
    notification_id: str,
    worker_id: str,
):
    await db.execute(
        """
        DELETE FROM notifications
        WHERE id = %s AND worker_id = %s
        """,
        (notification_id, worker_id)
    )


async def get_notification_by_id(
    db: AsyncConnection,
    notification_id: str,
    worker_id: str,
):
    row = await db.execute(
        """
        SELECT id, worker_id, title, message,
               is_read, created_at
        FROM notifications
        WHERE id = %s AND worker_id = %s
        """,
        (notification_id, worker_id)
    )
    return await row.fetchone()
