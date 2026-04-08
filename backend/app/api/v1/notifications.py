from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection

from app.core.database import get_db
from app.models.schemas import (
    NotificationResponse,
    NotificationListResponse,
)
from app.db.queries.notifications import (
    get_worker_notifications,
    get_unread_count,
    mark_notification_read,
    mark_all_read,
    delete_notification,
    get_notification_by_id,
)
from app.api.v1.deps import get_current_worker

router = APIRouter()


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    limit: int = 50,
    offset: int = 0,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    worker_id = str(current_worker["id"])

    notifications = await get_worker_notifications(
        db, worker_id, limit, offset
    )
    unread_count = await get_unread_count(db, worker_id)

    return NotificationListResponse(
        notifications=[
            NotificationResponse(**dict(n))
            for n in notifications
        ],
        unread_count=unread_count,
        total=len(notifications),
    )


@router.get("/unread-count")
async def unread_count(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    count = await get_unread_count(
        db, str(current_worker["id"])
    )
    return {"unread_count": count}


@router.put("/{notification_id}/read",
            response_model=NotificationResponse)
async def mark_read(
    notification_id: str,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    notification = await mark_notification_read(
        db, notification_id, str(current_worker["id"])
    )

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    await db.commit()
    return NotificationResponse(**dict(notification))


@router.put("/read-all", status_code=204)
async def read_all(
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    await mark_all_read(db, str(current_worker["id"]))
    await db.commit()


@router.delete("/{notification_id}", status_code=204)
async def delete(
    notification_id: str,
    current_worker=Depends(get_current_worker),
    db: AsyncConnection = Depends(get_db),
):
    existing = await get_notification_by_id(
        db, notification_id, str(current_worker["id"])
    )

    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    await delete_notification(
        db, notification_id, str(current_worker["id"])
    )
    await db.commit()
