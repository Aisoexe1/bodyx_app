from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.repos import support_ticket_repo
from app.schemas.support import TicketCreate, TicketMessageCreate, TicketOut, ticket_doc_to_out
from app.security import get_current_user

router = APIRouter(prefix="/support", tags=["support"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


@router.post("/tickets", response_model=TicketOut, status_code=status.HTTP_201_CREATED)
async def create_ticket(
    payload: TicketCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    doc = await support_ticket_repo.create_ticket(
        db, current_user["_id"], current_user["username"], payload.subject, payload.message
    )
    return ticket_doc_to_out(doc)


@router.get("/tickets", response_model=list[TicketOut])
async def list_tickets(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    docs = await support_ticket_repo.list_tickets_for_user(db, current_user["_id"])
    return [ticket_doc_to_out(d) for d in docs]


def _owned_ticket_or_404(doc: dict | None, user_id) -> dict:
    if doc is None or doc["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")
    return doc


@router.get("/tickets/{ticket_id}", response_model=TicketOut)
async def get_ticket(
    ticket_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    doc = await support_ticket_repo.find_by_id(db, ticket_id)
    doc = _owned_ticket_or_404(doc, current_user["_id"])
    return ticket_doc_to_out(doc)


@router.post("/tickets/{ticket_id}/messages", response_model=TicketOut)
async def add_message(
    ticket_id: str,
    payload: TicketMessageCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    doc = await support_ticket_repo.find_by_id(db, ticket_id)
    doc = _owned_ticket_or_404(doc, current_user["_id"])
    updated = await support_ticket_repo.add_user_message(db, doc["_id"], payload.text)
    return ticket_doc_to_out(updated)
