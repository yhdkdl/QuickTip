from fastapi import APIRouter, Depends, Query
from psycopg import AsyncConnection

from app.core.database import get_db
from app.models.schemas import (
    DashboardResponse,
    TipHistoryResponse,
    EarningsSummary,
    PeriodEarnings,
    TipHistoryItem,
)
from app.db.queries.dashboard import (
    get_earnings_summary,
    get_recent_tips,
    get_tip_history,
)
from app.api.v1.deps import get_current_worker

router = APIRouter()


@router.get("/earnings", response_model=DashboardResponse)
async def get_earnings(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_id = str(current_worker["id"])

    summary_row = await get_earnings_summary(db, worker_id)
    recent = await get_recent_tips(db, worker_id, limit=5)

    summary = EarningsSummary(
        all_time=PeriodEarnings(
            total=float(summary_row["all_time_total"]),
            count=int(summary_row["all_time_count"]),
        ),
        today=PeriodEarnings(
            total=float(summary_row["today_total"]),
            count=int(summary_row["today_count"]),
        ),
        this_week=PeriodEarnings(
            total=float(summary_row["week_total"]),
            count=int(summary_row["week_count"]),
        ),
        this_month=PeriodEarnings(
            total=float(summary_row["month_total"]),
            count=int(summary_row["month_count"]),
        ),
        average_tip=float(summary_row["average_tip"]),
        largest_tip=float(summary_row["largest_tip"]),
    )

    recent_tips = [
        TipHistoryItem(
            id=str(t["id"]),
            gross_amount=float(t["gross_amount"]),
            platform_fee=float(t["platform_fee"]),
            worker_payout=float(t["worker_payout"]),
            payment_reference=t["payment_reference"],
            initiated_via=t["initiated_via"],
            created_at=t["created_at"],
        )
        for t in recent
    ]

    return DashboardResponse(
        earnings=summary,
        recent_tips=recent_tips,
    )


@router.get("/tips", response_model=TipHistoryResponse)
async def get_tips_history(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_id = str(current_worker["id"])

    tips, total = await get_tip_history(
        db, worker_id, page, page_size
    )

    tip_items = [
        TipHistoryItem(
            id=str(t["id"]),
            gross_amount=float(t["gross_amount"]),
            platform_fee=float(t["platform_fee"]),
            worker_payout=float(t["worker_payout"]),
            payment_reference=t["payment_reference"],
            initiated_via=t["initiated_via"],
            created_at=t["created_at"],
        )
        for t in tips
    ]

    return TipHistoryResponse(
        tips=tip_items,
        total=total,
        page=page,
        page_size=page_size,
        has_more=(page * page_size) < total,
    )