from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import get_settings
from app.core.database import connect_db, disconnect_db
from app.api.v1 import auth

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 Starting {settings.app_name}")
    await connect_db()
    yield
    await disconnect_db()
    print(f"👋 {settings.app_name} shut down")


app = FastAPI(
    title=settings.app_name,
    description="M-Pesa tipping platform API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.frontend_url,
        "http://localhost:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "app": settings.app_name,
        "environment": settings.daraja_env
    }