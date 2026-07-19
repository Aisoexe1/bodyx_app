from datetime import datetime

from pydantic import Field

from app.schemas.common import CamelModel, PyObjectId


class AnnouncementOut(CamelModel):
    id: PyObjectId = Field(alias="id")
    message: str
    created_at: datetime


def announcement_doc_to_out(doc: dict) -> AnnouncementOut:
    return AnnouncementOut.model_validate({**doc, "id": doc["_id"]})
