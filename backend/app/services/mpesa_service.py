import base64
from datetime import datetime

import httpx

from app.core.config import get_settings

settings = get_settings()

SANDBOX_BASE = "https://sandbox.safaricom.co.ke"
LIVE_BASE = "https://api.safaricom.co.ke"


def get_base_url() -> str:
    return SANDBOX_BASE if settings.daraja_env == "sandbox" else LIVE_BASE


async def get_access_token() -> str:
    credentials = f"{settings.daraja_consumer_key}:{settings.daraja_consumer_secret}"
    encoded = base64.b64encode(credentials.encode()).decode()

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{get_base_url()}/oauth/v1/generate?grant_type=client_credentials",
            headers={"Authorization": f"Basic {encoded}"},
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()
        return data["access_token"]


def generate_password() -> tuple[str, str]:
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    raw = f"{settings.daraja_shortcode}{settings.daraja_passkey}{timestamp}"
    password = base64.b64encode(raw.encode()).decode()
    return password, timestamp


async def stk_push(
    phone: str,
    amount: float,
    session_id: str,
    worker_name: str,
) -> dict:
    token = await get_access_token()
    password, timestamp = generate_password()

    callback_url = f"{settings.backend_url}/api/v1/mpesa/callback"
    amount_int = int(amount)

    payload = {
        "BusinessShortCode": settings.daraja_shortcode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount_int,
        "PartyA": phone,
        "PartyB": settings.daraja_shortcode,
        "PhoneNumber": phone,
        "CallBackURL": callback_url,
        "AccountReference": f"QuickTip-{session_id[:8]}",
        "TransactionDesc": f"Tip for {worker_name}",
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{get_base_url()}/mpesa/stkpush/v1/processrequest",
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            timeout=30.0,
        )
        response.raise_for_status()
        return response.json()

