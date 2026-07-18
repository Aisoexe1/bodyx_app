from datetime import datetime
from enum import Enum

from pydantic import Field

from app.schemas.common import CamelModel, PyObjectId


class TicketStatus(str, Enum):
    open = "open"
    closed = "closed"


class TicketMessageSender(str, Enum):
    user = "user"
    admin = "admin"


class TicketMessage(CamelModel):
    sender: TicketMessageSender
    text: str
    created_at: datetime


class TicketCreate(CamelModel):
    subject: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=4000)


class TicketMessageCreate(CamelModel):
    text: str = Field(min_length=1, max_length=4000)


class TicketOut(CamelModel):
    id: PyObjectId = Field(alias="id")
    user_id: PyObjectId
    username: str
    subject: str
    status: TicketStatus
    messages: list[TicketMessage]
    created_at: datetime
    updated_at: datetime


def ticket_doc_to_out(doc: dict) -> TicketOut:
    return TicketOut.model_validate({**doc, "id": doc["_id"]})
