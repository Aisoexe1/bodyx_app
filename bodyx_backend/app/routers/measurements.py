from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.repos import measurement_repo
from app.schemas.measurement import MeasurementsMap, MeasurementZoneUpdate, MuscleZone
from app.security import get_current_user

router = APIRouter(prefix="/measurements", tags=["measurements"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


def _zones_to_map(zones: dict) -> MeasurementsMap:
    return {MuscleZone(k): v for k, v in zones.items()}


@router.get("", response_model=MeasurementsMap)
async def get_measurements(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    doc = await measurement_repo.get_measurements(db, current_user["_id"])
    if doc is None:
        doc = await measurement_repo.seed_measurements(db, current_user["_id"], current_user.get("gender", "male"))
    return _zones_to_map(doc["zones"])


@router.put("", response_model=MeasurementsMap)
async def replace_measurements(
    payload: MeasurementsMap,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    zones = {zone.value: value.model_dump() for zone, value in payload.items()}
    doc = await measurement_repo.replace_measurements(db, current_user["_id"], zones)
    return _zones_to_map(doc["zones"])


@router.patch("/{zone}", response_model=MeasurementsMap)
async def update_zone(
    zone: MuscleZone,
    payload: MeasurementZoneUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    doc = await measurement_repo.update_zone(db, current_user["_id"], zone.value, payload.value_cm)
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No measurements found for this user")
    return _zones_to_map(doc["zones"])
