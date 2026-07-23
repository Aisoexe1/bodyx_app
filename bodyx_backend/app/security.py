from datetime import datetime, timedelta, timezone

import jwt
from bson import ObjectId
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from passlib.context import CryptContext
from passlib.exc import PasswordTruncateError

from app.config import settings
from app.database import get_database

# bcrypt only ever looks at the first 72 bytes of its input — without
# bcrypt__truncate_error, passlib silently hashes just that prefix, so two
# different passwords sharing the same first 72 bytes would verify as equal
# and nothing warns a user who deliberately picked a longer passphrase that
# most of it was ignored. Rejecting outright is safer than accepting it.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__truncate_error=True)
bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    try:
        return pwd_context.hash(password)
    except PasswordTruncateError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Password is too long (max 72 bytes)",
        )


def verify_password(password: str, password_hash: str) -> bool:
    # UserLogin.password has no max_length, so a login attempt (unlike
    # registration/reset) can submit an arbitrarily long string — with
    # bcrypt__truncate_error on, that raises rather than returning False.
    # Treat it as simply not matching: no real password was ever hashed
    # past 72 bytes, so an over-length candidate can never be correct.
    try:
        return pwd_context.verify(password, password_hash)
    except PasswordTruncateError:
        return False


def create_access_token(user_id: str, token_version: int = 0) -> str:
    # `ver` lets a password reset invalidate every token issued before it —
    # without it, a JWT is a pure bearer credential for its whole 30-day
    # life with no way to revoke a specific one short of rotating the
    # global jwt_secret (which would log out every user, not just one).
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": user_id, "ver": token_version, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> tuple[str, int]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    # Tokens signed before this field existed have no "ver" claim at all —
    # treat that the same as version 0, matching user_repo's default for
    # accounts with no token_version field yet, so nothing already in
    # someone's hands the day this ships gets logged out for free.
    token_version = payload.get("ver", 0)
    return user_id, token_version


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    user_id, token_version = decode_access_token(credentials.credentials)

    db = get_database()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token subject")

    user = await db.users.find_one({"_id": oid})
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    if user.get("is_banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been banned")

    if token_version != user.get("token_version", 0):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="This token was issued before the most recent password reset",
        )

    return user
