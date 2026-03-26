from pathlib import Path

import qrcode
import qrcode.image.svg  # noqa: F401

from app.core.config import get_settings

settings = get_settings()

QR_DIR = Path("static/qr_codes")


def generate_worker_qr(worker_id: str) -> tuple[str, str]:
    tip_url = f"{settings.frontend_url}/tip/{worker_id}"

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )

    qr.add_data(tip_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    QR_DIR.mkdir(parents=True, exist_ok=True)

    file_path = QR_DIR / f"{worker_id}.png"
    img.save(str(file_path))

    qr_code_url = f"{settings.backend_url}/static/qr_codes/{worker_id}.png"

    return qr_code_url, tip_url

