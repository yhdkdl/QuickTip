from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool
from app.core.config import get_settings

settings = get_settings()

pool: AsyncConnectionPool | None = None


async def connect_db():
    global pool
    pool = AsyncConnectionPool(
        conninfo=settings.database_url,
        kwargs={"row_factory": dict_row},
        min_size=2,
        max_size=10,
    )
    await pool.open()
    print("✅ Database connected")


async def disconnect_db():
    global pool
    if pool:
        await pool.close()
        print("🔌 Database disconnected")


async def get_db():
    async with pool.connection() as connection:
        yield connection