from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.repos import user_repo
from app.schemas.user import UserPublic, UserUpdate, user_doc_to_public
from app.security import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


@router.get("/me", response_model=UserPublic)
async def get_me(current_user: dict = Depends(get_current_user)):
    return user_doc_to_public(current_user)


@router.patch("/me", response_model=UserPublic)
async def update_me(
    payload: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    updates = payload.model_dump(exclude_unset=True)
    if "username" in updates and updates["username"] != current_user["username"]:
        existing = await user_repo.find_by_username(db, updates["username"])
        if existing is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")
    if "gender" in updates and updates["gender"] is not None:
        updates["gender"] = updates["gender"].value if hasattr(updates["gender"], "value") else updates["gender"]

    updated = await user_repo.update_user(db, current_user["_id"], updates)
    return user_doc_to_public(updated)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    await user_repo.delete_user(db, current_user["_id"])
