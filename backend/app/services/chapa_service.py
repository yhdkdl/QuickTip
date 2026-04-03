import httpx
from app.core.config import get_settings
from typing import Optional

settings = get_settings()

CHAPA_BASE = "https://api.chapa.co/v1"


def get_headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.chapa_secret_key}",
        "Content-Type": "application/json",
    }


async def initialize_payment(
    amount: float,
    customer_phone: str,
    session_id: str,
    worker_name: str,
    customer_email: Optional[str] = None,
) -> dict:
    tx_ref = f"quicktip-{session_id}"

    return_url = (
        f"{settings.frontend_url}/tip/success"
        f"?session_id={session_id}&tx_ref={tx_ref}"
    )
    cancel_url = (
        f"{settings.frontend_url}/tip/cancelled"
        f"?session_id={session_id}"
    )

    payload = {
        "amount": str(round(amount, 2)),
        "currency": "ETB",
        "phone_number": customer_phone,
        "tx_ref": tx_ref,
        "callback_url": f"{settings.backend_url}/api/v1/chapa/webhook",
        "return_url": return_url,
        "cancel_url": cancel_url,
        "customization[title]": f"Tip for {worker_name}",
        "customization[description]": "QuickTip — thank your service worker",
    }

    if customer_email:
        payload["email"] = customer_email

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{CHAPA_BASE}/transaction/initialize",
            json=payload,
            headers=get_headers(),
            timeout=30.0,
        )
        response.raise_for_status()
        return response.json()


async def verify_payment(tx_ref: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{CHAPA_BASE}/transaction/verify/{tx_ref}",
            headers=get_headers(),
            timeout=30.0,
        )
        response.raise_for_status()
        return response.json()