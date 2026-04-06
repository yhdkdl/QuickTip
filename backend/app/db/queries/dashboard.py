from psycopg import AsyncConnection


async def get_earnings_summary(
    db: AsyncConnection,
    worker_id: str,
) -> dict:
    row = await db.execute(
        """
        SELECT
            COALESCE(SUM(worker_payout), 0)
                AS all_time_total,
            COUNT(*)
                AS all_time_count,

            COALESCE(SUM(
                CASE WHEN created_at >= CURRENT_DATE
                THEN worker_payout ELSE 0 END
            ), 0) AS today_total,
            COUNT(
                CASE WHEN created_at >= CURRENT_DATE
                THEN 1 END
            ) AS today_count,

            COALESCE(SUM(
                CASE WHEN created_at >= DATE_TRUNC('week', NOW())
                THEN worker_payout ELSE 0 END
            ), 0) AS week_total,
            COUNT(
                CASE WHEN created_at >= DATE_TRUNC('week', NOW())
                THEN 1 END
            ) AS week_count,

            COALESCE(SUM(
                CASE WHEN created_at >= DATE_TRUNC('month', NOW())
                THEN worker_payout ELSE 0 END
            ), 0) AS month_total,
            COUNT(
                CASE WHEN created_at >= DATE_TRUNC('month', NOW())
                THEN 1 END
            ) AS month_count,

            COALESCE(AVG(worker_payout), 0)
                AS average_tip,
            COALESCE(MAX(worker_payout), 0)
                AS largest_tip

        FROM tips
        WHERE worker_id = %s
        """,
        (worker_id,)
    )
    return await row.fetchone()


async def get_recent_tips(
    db: AsyncConnection,
    worker_id: str,
    limit: int = 5,
) -> list:
    rows = await db.execute(
        """
        SELECT
            t.id,
            t.gross_amount,
            t.platform_fee,
            t.worker_payout,
            t.payment_reference,
            t.created_at,
            ts.initiated_via
        FROM tips t
        JOIN tip_sessions ts ON ts.id = t.session_id
        WHERE t.worker_id = %s
        ORDER BY t.created_at DESC
        LIMIT %s
        """,
        (worker_id, limit)
    )
    return await rows.fetchall()


async def get_tip_history(
    db: AsyncConnection,
    worker_id: str,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list, int]:
    offset = (page - 1) * page_size

    rows = await db.execute(
        """
        SELECT
            t.id,
            t.gross_amount,
            t.platform_fee,
            t.worker_payout,
            t.payment_reference,
            t.created_at,
            ts.initiated_via
        FROM tips t
        JOIN tip_sessions ts ON ts.id = t.session_id
        WHERE t.worker_id = %s
        ORDER BY t.created_at DESC
        LIMIT %s OFFSET %s
        """,
        (worker_id, page_size, offset)
    )
    tips = await rows.fetchall()

    count_row = await db.execute(
        """
        SELECT COUNT(*) AS total FROM tips WHERE worker_id = %s
        """,
        (worker_id,)
    )
    total_row = await count_row.fetchone()
    total = int(total_row["total"]) if total_row else 0

    return tips, total