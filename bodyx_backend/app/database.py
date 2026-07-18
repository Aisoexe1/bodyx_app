from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.config import settings

_client: AsyncIOMotorClient | None = None


def connect() -> None:
    global _client
    _client = AsyncIOMotorClient(settings.mongo_uri)


def disconnect() -> None:
    global _client
    if _client is not None:
        _client.close()
        _client = None


def get_database() -> AsyncIOMotorDatabase:
    if _client is None:
        raise RuntimeError("Database client is not initialized. Call connect() first.")
    return _client[settings.mongo_db_name]


async def ensure_indexes() -> None:
    db = get_database()
    await db.users.create_index("email", unique=True)
    await db.users.create_index("username", unique=True)
    await db.weight_entries.create_index([("user_id", 1), ("date", 1)])
    await db.body_measurements.create_index("user_id", unique=True)
    await db.support_tickets.create_index([("user_id", 1), ("updated_at", -1)])
    # One-time (idempotent) backfill: users created before `auth_provider`
    # existed have no OAuth trail (the OAuth sign-in path always set it
    # explicitly), so a missing field means "local". Runs on every startup
    # but is a no-op once every doc has the field.
    await db.users.update_many(
        {"auth_provider": {"$exists": False}}, {"$set": {"auth_provider": "local"}}
    )
