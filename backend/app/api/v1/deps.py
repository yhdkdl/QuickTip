from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from psycopg import AsyncConnection

from app.core.database import get_db
from app.db.queries.workers import get_worker_by_id
from app.services.auth_service import decode_access_token

bearer_scheme = HTTPBearer()


async def get_current_worker(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncConnection = Depends(get_db),
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    worker_id = decode_access_token(credentials.credentials)
    if worker_id is None:
        raise credentials_exception

    worker = await get_worker_by_id(db, worker_id)
    if worker is None:
        raise credentials_exception

    return worker
