"""Password-reset email delivery via Brevo's HTTPS API. Falls back to
logging the code when no API key is configured (see
app.config.Settings.email_configured) so the reset flow is fully
buildable/testable before real credentials exist.

Raw SMTP was the first approach, but Render's free tier blocks outbound
SMTP traffic entirely (connections either failed immediately with
`OSError: Network is unreachable` or hung until timeout) — an HTTPS API
call sidesteps that since outbound port 443 isn't blocked.
"""

import logging
import re

import requests

from app.config import settings

logger = logging.getLogger("bodyx.email")

_BREVO_SEND_URL = "https://api.brevo.com/v3/smtp/email"
_REQUEST_TIMEOUT_SECONDS = 10

_FROM_RE = re.compile(r"^(?P<name>.*?)\s*<(?P<email>[^>]+)>$")


def _parse_sender(email_from: str) -> dict:
    match = _FROM_RE.match(email_from)
    if match:
        return {"name": match.group("name") or "BodyX", "email": match.group("email")}
    return {"name": "BodyX", "email": email_from}


def send_password_reset_email(to_email: str, code: str) -> None:
    if not settings.email_configured:
        logger.warning("DEV MODE (no email provider configured) — password reset code for %s: %s", to_email, code)
        return

    text = (
        f"Your BodyX password reset code is: {code}\n\n"
        f"This code expires in {settings.password_reset_code_ttl_minutes} minutes. "
        "If you didn't request this, you can ignore this email."
    )
    payload = {
        "sender": _parse_sender(settings.email_from),
        "to": [{"email": to_email}],
        "subject": "Your BodyX password reset code",
        "textContent": text,
    }
    response = requests.post(
        _BREVO_SEND_URL,
        json=payload,
        headers={"api-key": settings.brevo_api_key, "Content-Type": "application/json"},
        timeout=_REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
