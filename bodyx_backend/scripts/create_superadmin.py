"""One-off CLI to bootstrap the first superadmin account, since role
management in the admin panel itself requires an existing superadmin to
grant it (chicken-and-egg). Run with: python -m scripts.create_superadmin
"""

import asyncio
import getpass
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorClient

from app.config import settings
from app.security import hash_password


async def main() -> None:
    email = input("Superadmin email: ").strip().lower()
    username = input("Superadmin username: ").strip()
    password = getpass.getpass("Superadmin password (min 8 chars): ")
    if len(password) < 8:
        print("Password must be at least 8 characters.")
        return

    client = AsyncIOMotorClient(settings.mongo_uri)
    db = client[settings.mongo_db_name]

    if await db.users.find_one({"$or": [{"email": email}, {"username": username}]}):
        print("A user with that email or username already exists.")
        client.close()
        return

    now = datetime.now(timezone.utc)
    await db.users.insert_one(
        {
            "email": email,
            "username": username,
            "password_hash": hash_password(password),
            "gender": "male",
            "height_cm": 190,
            "weight_kg": 75,
            "age": 19,
            "goal": "Build muscle",
            "activity_level": "Moderately active",
            "units_metric": True,
            "avatar_seed": 0,
            "role": "superadmin",
            "is_banned": False,
            "created_at": now,
            "updated_at": now,
        }
    )
    client.close()
    print(f"Superadmin '{username}' created. Log in at http://localhost:8000/admin")


if __name__ == "__main__":
    asyncio.run(main())
