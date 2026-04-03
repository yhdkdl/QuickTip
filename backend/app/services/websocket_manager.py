import json
from fastapi import WebSocket


class WebSocketManager:
    def __init__(self):
        self.active: dict[str, WebSocket] = {}

    async def connect(self, session_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active[session_id] = websocket

    def disconnect(self, session_id: str):
        self.active.pop(session_id, None)

    async def send(self, session_id: str, data: dict):
        websocket = self.active.get(session_id)
        if websocket:
            try:
                await websocket.send_text(json.dumps(data))
            except Exception:
                self.disconnect(session_id)

    def is_connected(self, session_id: str) -> bool:
        return session_id in self.active


manager = WebSocketManager()
