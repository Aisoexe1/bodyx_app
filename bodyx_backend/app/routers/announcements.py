from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.repos import announcement_repo
from app.schemas.announcement import AnnouncementOut, announcement_doc_to_out
from app.security import get_current_user

router = APIRouter(prefix="/announcements", tags=["announcements"])


def _get_db() -> AsyncIOMotorDatabase:
    return get_database()


@router.get("/active", response_model=list[AnnouncementOut])
async def list_active_announcements(
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(_get_db),
):
    docs = await announcement_repo.list_active(db)
    return [announcement_doc_to_out(d) for d in docs]
