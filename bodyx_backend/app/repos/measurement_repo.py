from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repos.seed import default_measurements


async def get_measurements(db: AsyncIOMotorDatabase, user_id: ObjectId) -> dict | None:
    return await db.body_measurements.find_one({"user_id": user_id})


async def seed_measurements(db: AsyncIOMotorDatabase, user_id: ObjectId, gender: str) -> dict:
    doc = {
        "user_id": user_id,
        "zones": default_measurements(gender),
        "updated_at": datetime.now(timezone.utc),
    }
    await db.body_measurements.update_one(
        {"user_id": user_id}, {"$setOnInsert": doc}, upsert=True
    )
    return await db.body_measurements.find_one({"user_id": user_id})


async def replace_measurements(db: AsyncIOMotorDatabase, user_id: ObjectId, zones: dict) -> dict:
    await db.body_measurements.update_one(
        {"user_id": user_id},
        {"$set": {"zones": zones, "updated_at": datetime.now(timezone.utc)}},
        upsert=True,
    )
    return await db.body_measurements.find_one({"user_id": user_id})


async def update_zone(db: AsyncIOMotorDatabase, user_id: ObjectId, zone: str, value_cm: float) -> dict | None:
    existing = await db.body_measurements.find_one({"user_id": user_id})
    if existing is None:
        return None
    zone_data = existing["zones"].get(zone, {"value_cm": value_cm, "history": [], "target_cm": value_cm})
    new_history = [*zone_data.get("history", []), value_cm]
    updated_zone = {**zone_data, "value_cm": value_cm, "history": new_history}
    await db.body_measurements.update_one(
        {"user_id": user_id},
        {
            "$set": {
                f"zones.{zone}": updated_zone,
                "updated_at": datetime.now(timezone.utc),
            }
        },
    )
    return await db.body_measurements.find_one({"user_id": user_id})
