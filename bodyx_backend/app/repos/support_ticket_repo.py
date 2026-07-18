from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


async def create_ticket(
    db: AsyncIOMotorDatabase, user_id: ObjectId, username: str, subject: str, message: str
) -> dict:
    now = datetime.now(timezone.utc)
    doc = {
        "user_id": user_id,
        "username": username,
        "subject": subject,
        "status": "open",
        "messages": [{"sender": "user", "text": message, "created_at": now}],
        "created_at": now,
        "updated_at": now,
    }
    result = await db.support_tickets.insert_one(doc)
    doc["_id"] = result.inserted_id
    return doc


async def list_tickets_for_user(db: AsyncIOMotorDatabase, user_id: ObjectId) -> list[dict]:
    return await db.support_tickets.find({"user_id": user_id}).sort("updated_at", -1).to_list(length=None)


async def find_by_id(db: AsyncIOMotorDatabase, ticket_id: str) -> dict | None:
    try:
        oid = ObjectId(ticket_id)
    except Exception:
        return None
    return await db.support_tickets.find_one({"_id": oid})


async def add_user_message(db: AsyncIOMotorDatabase, ticket_id: ObjectId, text: str) -> dict | None:
    now = datetime.now(timezone.utc)
    # A user message on a closed ticket reopens it — mirrors how any normal
    # support inbox behaves, and avoids a dead end where the user has no way
    # to follow up once an admin closes the thread.
    await db.support_tickets.update_one(
        {"_id": ticket_id},
        {
            "$push": {"messages": {"sender": "user", "text": text, "created_at": now}},
            "$set": {"updated_at": now, "status": "open"},
        },
    )
    return await db.support_tickets.find_one({"_id": ticket_id})
