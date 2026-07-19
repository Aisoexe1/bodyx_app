import asyncio

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config import settings
from app.database import get_database
from app.email_service import send_password_reset_email
from app.oauth import OAuthVerificationError, verify_apple_identity_token, verify_google_id_token
from app.repos import measurement_repo, password_reset_repo, user_repo
from app.schemas.user import (
    AppleAuthRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    GoogleAuthRequest,
    ResetPasswordRequest,
    Token,
    UserCreate,
    UserLogin,
    user_doc_to_public,
)
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(payload: UserCreate, db: AsyncIOMotorDatabase = Depends(_get_db)):
    if await user_repo.find_by_email(db, payload.email):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    if await user_repo.find_by_username(db, payload.username):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")

    doc = payload.model_dump(exclude={"password"})
    doc["password_hash"] = hash_password(payload.password)
    user = await user_repo.create_user(db, doc)

    await measurement_repo.seed_measurements(db, user["_id"], payload.gender.value)

    token = create_access_token(str(user["_id"]))
    return Token(access_token=token, user=user_doc_to_public(user))


@router.post("/login", response_model=Token)
async def login(payload: UserLogin, db: AsyncIOMotorDatabase = Depends(_get_db)):
    user = await user_repo.find_by_email(db, payload.email)
    if user is None or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if user.get("is_banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been banned")

    token = create_access_token(str(user["_id"]))
    return Token(access_token=token, user=user_doc_to_public(user))


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
async def forgot_password(
    payload: ForgotPasswordRequest, db: AsyncIOMotorDatabase = Depends(_get_db)
):
    # Always a generic message — never reveal whether the email is registered.
    generic_message = "If an account with that email exists, a reset code has been sent."

    user = await user_repo.find_by_email(db, payload.email)
    if user is None:
        return ForgotPasswordResponse(message=generic_message)

    code = await password_reset_repo.create_code(db, user["_id"])
    await asyncio.to_thread(send_password_reset_email, user["email"], code)

    if settings.smtp_configured:
        return ForgotPasswordResponse(message=generic_message)
    # Dev mode (no SMTP): echo the code back so the flow is testable without
    # an inbox. Never happens once SMTP is configured.
    return ForgotPasswordResponse(message=generic_message, dev_code=code)


@router.post("/reset-password", response_model=Token)
async def reset_password(
    payload: ResetPasswordRequest, db: AsyncIOMotorDatabase = Depends(_get_db)
):
    user = await user_repo.find_by_email(db, payload.email)
    if user is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired code")
    if user.get("is_banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been banned")

    record = await password_reset_repo.find_valid_code(db, user["_id"], payload.code)
    if record is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired code")

    await user_repo.set_password_hash(db, user["_id"], hash_password(payload.new_password))
    await password_reset_repo.mark_used(db, record["_id"])

    updated_user = await user_repo.find_by_id(db, str(user["_id"]))
    token = create_access_token(str(updated_user["_id"]))
    return Token(access_token=token, user=user_doc_to_public(updated_user))


@router.post("/oauth/google", response_model=Token)
async def oauth_google(payload: GoogleAuthRequest, db: AsyncIOMotorDatabase = Depends(_get_db)):
    try:
        info = verify_google_id_token(payload.id_token)
    except OAuthVerificationError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token")

    user = await user_repo.find_or_create_oauth_user(db, info["email"], info["name"], "google")
    if user.get("is_banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been banned")
    await measurement_repo.seed_measurements(db, user["_id"], user.get("gender", "male"))

    token = create_access_token(str(user["_id"]))
    return Token(access_token=token, user=user_doc_to_public(user))


@router.post("/oauth/apple", response_model=Token)
async def oauth_apple(payload: AppleAuthRequest, db: AsyncIOMotorDatabase = Depends(_get_db)):
    try:
        info = verify_apple_identity_token(payload.identity_token)
    except OAuthVerificationError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Apple token")

    user = await user_repo.find_or_create_oauth_user(db, info["email"], info["name"], "apple")
    if user.get("is_banned"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been banned")
    await measurement_repo.seed_measurements(db, user["_id"], user.get("gender", "male"))

    token = create_access_token(str(user["_id"]))
    return Token(access_token=token, user=user_doc_to_public(user))
