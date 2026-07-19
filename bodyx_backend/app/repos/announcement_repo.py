from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorDatabase


async def list_active(db: AsyncIOMotorDatabase) -> list[dict]:
    now = datetime.now(timezone.utc)
    cursor = db.announcements.find(
        {
            "active": True,
            "$or": [{"expires_at": None}, {"expires_at": {"$exists": False}}, {"expires_at": {"$gt": now}}],
        }
    ).sort("created_at", -1)
    return await cursor.to_list(length=None)
