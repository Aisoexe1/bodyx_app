from datetime import datetime
from typing import Optional

from pydantic import Field

from app.schemas.common import CamelModel, PyObjectId


class WeightEntryCreate(CamelModel):
    date: Optional[datetime] = None
    kg: float
    body_fat_pct: float


class WeightEntryOut(CamelModel):
    id: PyObjectId = Field(alias="id")
    date: datetime
    kg: float
    body_fat_pct: float
