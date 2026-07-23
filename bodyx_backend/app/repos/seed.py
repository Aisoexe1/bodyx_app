"""Default body-measurement seeding, mirroring MockData.generateBodyMeasurements
in bodyx_app/lib/data/mock_data.dart so a freshly registered user sees the same
kind of starting data the client used to fabricate locally."""

import random

from app.schemas.measurement import MuscleZone

_BASE_BY_GENDER = {
    "male": {
        MuscleZone.shoulders: 118,
        MuscleZone.chest: 104,
        MuscleZone.biceps: 36,
        MuscleZone.forearms: 29,
        MuscleZone.abs: 84,
        MuscleZone.back: 112,
        MuscleZone.quads: 58,
        MuscleZone.hamstrings: 41,
        MuscleZone.calves: 38,
        MuscleZone.glutes: 98,
    },
    "female": {
        MuscleZone.shoulders: 102,
        MuscleZone.chest: 92,
        MuscleZone.biceps: 27,
        MuscleZone.forearms: 23,
        MuscleZone.abs: 71,
        MuscleZone.back: 96,
        MuscleZone.quads: 55,
        MuscleZone.hamstrings: 39,
        MuscleZone.calves: 34,
        MuscleZone.glutes: 101,
    },
}


def default_measurements(gender: str) -> dict:
    rng = random.Random(42)
    base = _BASE_BY_GENDER.get(gender, _BASE_BY_GENDER["male"])
    zones: dict[str, dict] = {}
    for zone in MuscleZone:
        target = base[zone]
        history = []
        for i in range(6):
            drift = (5 - i) * (0.4 + rng.random() * 0.5)
            history.append(round(target - drift, 1))
        zones[zone.value] = {
            "value_cm": history[-1],
            "history": history,
            "target_cm": round(target + 4, 1),
        }
    return zones
