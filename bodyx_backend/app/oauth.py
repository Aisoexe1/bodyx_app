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


def _is_email_verified(claims: dict) -> bool:
    """`email_verified` is what Google's own docs say callers must check
    before treating the token's email as trustworthy/permanent — without
    it, a provider-issued token asserting an email the holder doesn't
    actually control could get bound to a new account here. Apple's SDKs
    are known to send this as the *string* "true"/"false" rather than a
    real JSON boolean, so this can't just do `bool(claims.get(...))`.
    Missing entirely (some flows omit it) is treated as verified — this
    only rejects an *explicit* false, not silence."""
    verified = claims.get("email_verified")
    if verified is None:
        return True
    if isinstance(verified, str):
        return verified.lower() == "true"
    return bool(verified)


def verify_google_id_token(token: str) -> dict:
    if not settings.google_oauth_configured:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Google sign-in is not configured yet",
        )
    try:
        # No `audience` passed here — verify_oauth2_token would only accept
        # a single exact match, but a valid token may carry either the
        # web/server client ID or the iOS client ID as `aud` (see
        # Settings.google_ios_client_id). Signature/expiry are still fully
        # verified; only the audience check moves below.
        claims = google_id_token.verify_oauth2_token(token, _google_request)
    except Exception as e:
        raise OAuthVerificationError(str(e)) from e

    allowed_audiences = {
        aud for aud in (settings.google_client_id, settings.google_ios_client_id) if aud
    }
    if claims.get("aud") not in allowed_audiences:
        raise OAuthVerificationError("Google token audience not recognized")

    email = claims.get("email")
    if not email:
        raise OAuthVerificationError("Google token did not include an email")
    if not _is_email_verified(claims):
        raise OAuthVerificationError("Google token's email is not verified")
    return {"email": email}


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
    if not _is_email_verified(claims):
        raise OAuthVerificationError("Apple token's email is not verified")
    return {"email": email}
