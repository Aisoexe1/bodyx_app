import secrets
from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.security import hash_password


async def find_by_email(db: AsyncIOMotorDatabase, email: str) -> dict | None:
    return await db.users.find_one({"email": email.lower()})


async def find_by_username(db: AsyncIOMotorDatabase, username: str) -> dict | None:
    return await db.users.find_one({"username": username})


async def find_by_id(db: AsyncIOMotorDatabase, user_id: str) -> dict | None:
    try:
        oid = ObjectId(user_id)
    except Exception:
        return None
    return await db.users.find_one({"_id": oid})


async def create_user(db: AsyncIOMotorDatabase, doc: dict) -> dict:
    now = datetime.now(timezone.utc)
    doc = {
        "auth_provider": "local",
        **doc,
        "email": doc["email"].lower(),
        "role": "user",
        "is_banned": False,
        # Bumped by set_password_hash on every password reset, and checked
        # against the "ver" claim in get_current_user — see app/security.py.
        "token_version": 0,
        "created_at": now,
        "updated_at": now,
    }
    result = await db.users.insert_one(doc)
    doc["_id"] = result.inserted_id
    return doc


async def update_user(db: AsyncIOMotorDatabase, user_id: ObjectId, updates: dict) -> dict | None:
    if not updates:
        return await db.users.find_one({"_id": user_id})
    updates["updated_at"] = datetime.now(timezone.utc)
    await db.users.update_one({"_id": user_id}, {"$set": updates})
    return await db.users.find_one({"_id": user_id})


async def delete_user(db: AsyncIOMotorDatabase, user_id: ObjectId) -> None:
    """Full account deletion — matches the Privacy Policy's promise that
    deleting an account removes the associated data server-side too, not
    just the user document. Every collection that stores a user_id."""
    await db.weight_entries.delete_many({"user_id": user_id})
    await db.body_measurements.delete_many({"user_id": user_id})
    await db.support_tickets.delete_many({"user_id": user_id})
    await db.users.delete_one({"_id": user_id})


async def set_weight_kg(db: AsyncIOMotorDatabase, user_id: ObjectId, kg: float) -> None:
    await db.users.update_one(
        {"_id": user_id},
        {"$set": {"weight_kg": kg, "updated_at": datetime.now(timezone.utc)}},
    )


async def set_password_hash(db: AsyncIOMotorDatabase, user_id: ObjectId, password_hash: str) -> None:
    # $inc token_version in the same update, atomically, so a password
    # reset always invalidates every token issued before it — see
    # get_current_user's version check in app/security.py. There's no
    # separate "bump_token_version" call anywhere else to forget.
    await db.users.update_one(
        {"_id": user_id},
        {
            "$set": {"password_hash": password_hash, "updated_at": datetime.now(timezone.utc)},
            "$inc": {"token_version": 1},
        },
    )


async def create_oauth_user(
    db: AsyncIOMotorDatabase, email: str, username: str, auth_provider: str
) -> dict:
    """Creates a brand-new OAuth (Google/Apple) account with a user-chosen
    username — the caller has already verified it's not taken. Never
    auto-derives or auto-disambiguates a username from the email, so the
    user always picks (and knows) their own handle, same as local sign-up.
    Gets a random, never-used password hash so `password_hash` stays
    non-null for every user without special-casing the login/reset paths."""
    doc = {
        "email": email,
        "username": username,
        "password_hash": hash_password(secrets.token_urlsafe(32)),
        "gender": "male",
        "height_cm": 190,
        "weight_kg": 75,
        "age": 19,
        "goal": "Build muscle",
        "activity_level": "Moderately active",
        "units_metric": True,
        "avatar_seed": 0,
        "auth_provider": auth_provider,
    }
    return await create_user(db, doc)
