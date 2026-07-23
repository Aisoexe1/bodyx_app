import re
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import EmailStr, Field, field_validator

from app.schemas.common import CamelModel, PyObjectId


class Gender(str, Enum):
    male = "male"
    female = "female"


def validate_password_strength(value: str) -> str:
    if not re.search(r"[A-Za-z]", value):
        raise ValueError("Password must contain at least one letter")
    if not re.search(r"\d", value):
        raise ValueError("Password must contain at least one digit")
    return value


class UserCreate(CamelModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=32)
    password: str = Field(min_length=6, max_length=128)
    gender: Gender = Gender.male
    height_cm: float = 190
    weight_kg: float = 75
    age: int = 19
    goal: str = "Build muscle"
    activity_level: str = "Moderately active"
    units_metric: bool = True
    avatar_seed: int = 0

    _validate_password = field_validator("password")(validate_password_strength)


class UserLogin(CamelModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(CamelModel):
    email: EmailStr


class ForgotPasswordResponse(CamelModel):
    message: str
    # Dev-mode only (no SMTP configured) — the raw code, so the flow is
    # testable without an email inbox. Always None once SMTP is set.
    dev_code: Optional[str] = None


class ResetPasswordRequest(CamelModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=6, max_length=128)

    _validate_new_password = field_validator("new_password")(validate_password_strength)


class GoogleAuthRequest(CamelModel):
    id_token: str


class GoogleAuthCompleteRequest(CamelModel):
    id_token: str
    username: str = Field(min_length=3, max_length=32)


class AppleAuthRequest(CamelModel):
    identity_token: str


class AppleAuthCompleteRequest(CamelModel):
    identity_token: str
    username: str = Field(min_length=3, max_length=32)


class OAuthNeedsUsernameResponse(CamelModel):
    """Returned instead of a [Token] when an OAuth sign-in's email has no
    existing account yet — the client must collect a username and call the
    matching `/oauth/{provider}/complete` endpoint to actually create it."""

    needs_username: bool = True
    email: EmailStr


class UserUpdate(CamelModel):
    username: Optional[str] = Field(default=None, min_length=3, max_length=32)
    gender: Optional[Gender] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    age: Optional[int] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None
    units_metric: Optional[bool] = None
    avatar_seed: Optional[int] = None
    # The dragon pet's accumulated XP (see bodyx_app's AppState.petXp) — the
    # client computes and owns this value entirely (goal completion,
    # achievement bonuses, the admin-only boost), same trust model as
    # weight_kg/avatar_seed. The backend just stores whatever it's told so
    # progress survives a reinstall/new device instead of living only in
    # SharedPreferences.
    pet_xp: Optional[int] = Field(default=None, ge=0)


class UserPublic(CamelModel):
    id: PyObjectId = Field(alias="id")
    email: EmailStr
    username: str
    gender: Gender
    height_cm: float
    weight_kg: float
    age: int
    goal: str
    activity_level: str
    units_metric: bool
    avatar_seed: int
    role: str
    is_banned: bool
    pet_xp: int = 0
    created_at: datetime
    updated_at: datetime


class Token(CamelModel):
    access_token: str
    token_type: str = "bearer"
    user: UserPublic


def user_doc_to_public(doc: dict) -> UserPublic:
    return UserPublic.model_validate({**doc, "id": doc["_id"]})
