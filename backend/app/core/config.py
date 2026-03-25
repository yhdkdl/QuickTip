from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080
    daraja_consumer_key: str
    daraja_consumer_secret: str
    daraja_shortcode: str = "174379"
    daraja_passkey: str
    daraja_env: str = "sandbox"
    app_name: str = "QuickTip"
    platform_fee_percent: float = 2.0
    backend_url: str
    frontend_url: str = "http://localhost:3000"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()