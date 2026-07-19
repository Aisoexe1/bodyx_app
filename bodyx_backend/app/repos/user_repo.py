import re
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
    await db.users.update_one(
        {"_id": user_id},
        {"$set": {"password_hash": password_hash, "updated_at": datetime.now(timezone.utc)}},
    )


async def find_or_create_oauth_user(
    db: AsyncIOMotorDatabase, email: str, name: str, auth_provider: str
) -> dict:
    """Logs an OAuth (Google/Apple) identity into an existing local account
    with the same email, or creates a new one. OAuth-created accounts get a
    random, never-used password hash so `password_hash` stays non-null for
    every user without special-casing the login/reset code paths."""
    existing = await find_by_email(db, email)
    if existing:
        return existing

    base_username = re.sub(r"[^a-zA-Z0-9_]", "", email.split("@")[0])[:28] or "user"
    username = base_username
    suffix = 1
    while await find_by_username(db, username):
        suffix += 1
        username = f"{base_username}{suffix}"[:32]

    doc = {
        "email": email,
        "username": username,
        "password_hash": hash_password(secrets.token_urlsafe(32)),
        "name": name,
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
