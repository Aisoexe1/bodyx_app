"""Password-reset email delivery. Falls back to logging the code when no
SMTP is configured (see app.config.Settings.smtp_configured) so the reset
flow is fully buildable/testable before real SMTP credentials exist."""

import logging
import smtplib
from email.message import EmailMessage

from app.config import settings

logger = logging.getLogger("bodyx.email")


def send_password_reset_email(to_email: str, code: str) -> None:
    if not settings.smtp_configured:
        logger.warning("DEV MODE (no SMTP configured) — password reset code for %s: %s", to_email, code)
        return

    message = EmailMessage()
    message["Subject"] = "Your BodyX password reset code"
    message["From"] = settings.smtp_from
    message["To"] = to_email
    message.set_content(
        f"Your BodyX password reset code is: {code}\n\n"
        f"This code expires in {settings.password_reset_code_ttl_minutes} minutes. "
        "If you didn't request this, you can ignore this email."
    )

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
        if settings.smtp_use_tls:
            server.starttls()
        if settings.smtp_username and settings.smtp_password:
            server.login(settings.smtp_username, settings.smtp_password)
        server.send_message(message)
