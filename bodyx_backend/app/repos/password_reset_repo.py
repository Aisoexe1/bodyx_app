import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.config import settings


def _hash_code(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def generate_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


# A 6-digit code is only as safe as its TTL if every wrong guess is free —
# without a cap, the 15-minute window is no real barrier to brute-forcing
# all 1,000,000 combinations against a fast local endpoint. Locking the code
# out after a handful of wrong guesses (forcing a fresh /forgot-password
# request) closes that regardless of request rate/IP rotation.
MAX_ATTEMPTS = 5


async def create_code(db: AsyncIOMotorDatabase, user_id: ObjectId) -> str:
    # Invalidate any prior unused codes for this user so only the latest
    # request is ever valid.
    await db.password_reset_codes.update_many(
        {"user_id": user_id, "used": False}, {"$set": {"used": True}}
    )

    code = generate_code()
    now = datetime.now(timezone.utc)
    await db.password_reset_codes.insert_one(
        {
            "user_id": user_id,
            "code_hash": _hash_code(code),
            "expires_at": now + timedelta(minutes=settings.password_reset_code_ttl_minutes),
            "used": False,
            "attempts": 0,
            "created_at": now,
        }
    )
    return code


async def find_valid_code(db: AsyncIOMotorDatabase, user_id: ObjectId, code: str) -> dict | None:
    return await db.password_reset_codes.find_one(
        {
            "user_id": user_id,
            "code_hash": _hash_code(code),
            "used": False,
            "attempts": {"$lt": MAX_ATTEMPTS},
            "expires_at": {"$gt": datetime.now(timezone.utc)},
        }
    )


async def record_failed_attempt(db: AsyncIOMotorDatabase, user_id: ObjectId) -> None:
    """Counts a wrong-code submission against the user's current active
    code, whatever code they actually typed — called on every non-match so
    repeated guessing exhausts the budget instead of being free."""
    await db.password_reset_codes.update_one(
        {
            "user_id": user_id,
            "used": False,
            "expires_at": {"$gt": datetime.now(timezone.utc)},
        },
        {"$inc": {"attempts": 1}},
    )


async def mark_used(db: AsyncIOMotorDatabase, code_id: ObjectId) -> None:
    await db.password_reset_codes.update_one({"_id": code_id}, {"$set": {"used": True}})
