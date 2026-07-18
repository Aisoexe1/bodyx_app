from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


async def list_weight_entries(
    db: AsyncIOMotorDatabase,
    user_id: ObjectId,
    since: datetime | None = None,
    limit: int | None = None,
) -> list[dict]:
    query: dict = {"user_id": user_id}
    if since is not None:
        query["date"] = {"$gte": since}
    cursor = db.weight_entries.find(query).sort("date", 1)
    if limit:
        cursor = cursor.limit(limit)
    return await cursor.to_list(length=None)


async def add_weight_entry(
    db: AsyncIOMotorDatabase,
    user_id: ObjectId,
    date: datetime | None,
    kg: float,
    body_fat_pct: float,
) -> dict:
    doc = {
        "user_id": user_id,
        "date": date or datetime.now(timezone.utc),
        "kg": kg,
        "body_fat_pct": body_fat_pct,
        "created_at": datetime.now(timezone.utc),
    }
    result = await db.weight_entries.insert_one(doc)
    doc["_id"] = result.inserted_id
    return doc
