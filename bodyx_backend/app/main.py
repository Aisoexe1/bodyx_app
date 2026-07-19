from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import connect, disconnect, ensure_indexes
from app.routers import announcements, auth, measurements, support, users, weight


@asynccontextmanager
async def lifespan(app: FastAPI):
    connect()
    await ensure_indexes()
    yield
    disconnect()


app = FastAPI(title="BodyX API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(weight.router, prefix="/api/v1")
app.include_router(measurements.router, prefix="/api/v1")
app.include_router(support.router, prefix="/api/v1")
app.include_router(announcements.router, prefix="/api/v1")


@app.get("/api/v1/health")
async def health():
    return {"status": "ok"}


# Starlette-Admin panel, mounted at /admin (see app/admin/setup.py).
from app.admin.setup import build_admin  # noqa: E402

build_admin().mount_to(app)
