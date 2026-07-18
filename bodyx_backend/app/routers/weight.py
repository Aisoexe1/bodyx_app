from datetime import datetime

from fastapi import APIRouter, Depends, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.repos import user_repo, weight_repo
from app.schemas.weight import WeightEntryCreate, WeightEntryOut
from app.security import get_current_user

router = APIRouter(prefix="/weight", tags=["weight"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


def _to_out(doc: dict) -> WeightEntryOut:
    return WeightEntryOut.model_validate({**doc, "id": doc["_id"]})


@router.get("", response_model=list[WeightEntryOut])
async def list_weight(
    since: datetime | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1, le=1000),
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    entries = await weight_repo.list_weight_entries(db, current_user["_id"], since=since, limit=limit)
    return [_to_out(e) for e in entries]


@router.post("", response_model=WeightEntryOut, status_code=status.HTTP_201_CREATED)
async def add_weight(
    payload: WeightEntryCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    entry = await weight_repo.add_weight_entry(
        db, current_user["_id"], payload.date, payload.kg, payload.body_fat_pct
    )
    await user_repo.set_weight_kg(db, current_user["_id"], payload.kg)
    return _to_out(entry)
