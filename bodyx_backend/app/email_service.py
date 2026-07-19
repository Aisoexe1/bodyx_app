"""Password-reset email delivery. Falls back to logging the code when no
SMTP is configured (see app.config.Settings.smtp_configured) so the reset
flow is fully buildable/testable before real SMTP credentials exist."""

import logging
import smtplib
import socket
from email.message import EmailMessage

from app.config import settings

logger = logging.getLogger("bodyx.email")

# Some hosts (Render's free tier included) block or silently drop outbound
# SMTP entirely — without an explicit timeout, a blocked connection can hang
# the request for minutes instead of failing fast. Always bound it.
_CONNECT_TIMEOUT_SECONDS = 10


class _IPv4SMTP(smtplib.SMTP):
    """Some hosts advertise no outbound IPv6 route, but smtp.gmail.com (and
    other providers) resolve to an IPv6 address first — the connection then
    fails with `OSError: [Errno 101] Network is unreachable` before SMTP/TLS/
    auth ever get a chance to run. Forcing IPv4 resolution here sidesteps
    that specific case; `self._host` is left as the real hostname (set by
    the base constructor before connect() runs), so STARTTLS certificate
    hostname verification is unaffected. Does not help if outbound SMTP is
    blocked outright (see _CONNECT_TIMEOUT_SECONDS above for that case)."""

    def _get_socket(self, host, port, timeout):
        family, socktype, proto, _, sockaddr = socket.getaddrinfo(
            host, port, socket.AF_INET, socket.SOCK_STREAM
        )[0]
        sock = socket.socket(family, socktype, proto)
        sock.settimeout(_CONNECT_TIMEOUT_SECONDS if timeout is socket._GLOBAL_DEFAULT_TIMEOUT else timeout)
        sock.connect(sockaddr)
        return sock


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

    with _IPv4SMTP(settings.smtp_host, settings.smtp_port) as server:
        if settings.smtp_use_tls:
            server.starttls()
        if settings.smtp_username and settings.smtp_password:
            server.login(settings.smtp_username, settings.smtp_password)
        server.send_message(message)
