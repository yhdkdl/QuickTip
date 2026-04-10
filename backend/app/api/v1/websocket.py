from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.services.websocket_manager import manager

router = APIRouter()


@router.websocket("/ws/tips/{session_id}")
async def tip_websocket(session_id: str, websocket: WebSocket):
    await manager.connect(session_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(session_id)


@router.websocket("/ws/worker/{worker_id}")
async def worker_websocket(
    worker_id: str,
    websocket: WebSocket,
):
    await manager.connect_worker(worker_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_worker(worker_id)
