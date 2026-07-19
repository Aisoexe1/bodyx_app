"""Google/Apple ID-token verification. Each function trusts only the
provider's own public keys (Google's via google-auth, Apple's JWKS via
PyJWT) — we never trust claims without a verified signature."""

import jwt
from fastapi import HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from app.config import settings

_google_request = google_requests.Request()
_apple_jwks_client = jwt.PyJWKClient("https://appleid.apple.com/auth/keys")


class OAuthVerificationError(Exception):
    pass


def verify_google_id_token(token: str) -> dict:
    if not settings.google_oauth_configured:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Google sign-in is not configured yet",
        )
    try:
        claims = google_id_token.verify_oauth2_token(
            token, _google_request, settings.google_client_id
        )
    except Exception as e:
        raise OAuthVerificationError(str(e)) from e

    email = claims.get("email")
    if not email:
        raise OAuthVerificationError("Google token did not include an email")
    return {"email": email, "name": claims.get("name") or email.split("@")[0]}


def verify_apple_identity_token(token: str) -> dict:
    if not settings.apple_oauth_configured:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Apple sign-in is not configured yet",
        )
    try:
        signing_key = _apple_jwks_client.get_signing_key_from_jwt(token)
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=settings.apple_client_id,
            issuer="https://appleid.apple.com",
        )
    except Exception as e:
        raise OAuthVerificationError(str(e)) from e

    email = claims.get("email")
    if not email:
        raise OAuthVerificationError("Apple token did not include an email")
    return {"email": email, "name": email.split("@")[0]}
