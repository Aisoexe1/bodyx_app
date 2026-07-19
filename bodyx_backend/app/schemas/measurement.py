from enum import Enum

from pydantic import Field

from app.schemas.common import CamelModel


class MuscleZone(str, Enum):
    shoulders = "shoulders"
    chest = "chest"
    biceps = "biceps"
    forearms = "forearms"
    abs = "abs"
    quads = "quads"
    calves = "calves"
    back = "back"
    glutes = "glutes"
    hamstrings = "hamstrings"


class MeasurementZone(CamelModel):
    value_cm: float
    history: list[float] = Field(default_factory=list)
    target_cm: float


class MeasurementZoneUpdate(CamelModel):
    value_cm: float


MeasurementsMap = dict[MuscleZone, MeasurementZone]
