from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.config import settings
from app.database import connect, disconnect, ensure_indexes
from app.rate_limit import limiter
from app.routers import announcements, auth, measurements, support, users, weight

# These ship as the field defaults in app/config.py purely so the module can
# be imported (and so a brand-new clone doesn't crash before anyone's set up
# a .env) — they must never actually be what signs a real token or session
# cookie. Checked at real server startup, not at Settings() construction:
# the test suite's ASGITransport never runs the lifespan (conftest.py drives
# connect()/ensure_indexes() itself instead), so this never fires under
# pytest regardless of which checkout's .env (if any) it's run from.
_INSECURE_DEFAULT_JWT_SECRET = "dev-secret-change-me"
_INSECURE_DEFAULT_SESSION_SECRET = "dev-session-secret-change-me"


def _reject_insecure_default_secrets() -> None:
    if settings.jwt_secret == _INSECURE_DEFAULT_JWT_SECRET:
        raise RuntimeError(
            "Refusing to start: JWT_SECRET is still the insecure placeholder "
            "default. Set a real, random JWT_SECRET in .env."
        )
    if settings.session_secret == _INSECURE_DEFAULT_SESSION_SECRET:
        raise RuntimeError(
            "Refusing to start: SESSION_SECRET is still the insecure placeholder "
            "default. Set a real, random SESSION_SECRET in .env."
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    _reject_insecure_default_secrets()
    connect()
    await ensure_indexes()
    yield
    disconnect()


app = FastAPI(title="BodyX API", version="0.1.0", lifespan=lifespan)

# Rate limiting for the brute-forceable auth endpoints (login, register,
# password reset, OAuth) — see app/rate_limit.py and the @limiter.limit(...)
# decorators in app/routers/auth.py. Disabled during tests (autouse fixture
# in tests/conftest.py) so the existing suite's repeated /register calls
# from the same test-client IP never trip it.
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    # No cookie-based cross-origin calls exist to protect: this JSON API is
    # Bearer-token only (Authorization header, not a "credential" in the
    # CORS/fetch sense), and the admin panel's session cookie is same-origin
    # (mounted on this same app) so never needs CORS at all. Wildcard origin
    # + allow_credentials=True together would mean the browser reflects the
    # caller's actual Origin and could carry it into a cross-site cookie
    # request too — dropping the credentials flag we don't use closes that
    # off without needing an origin allowlist.
    allow_credentials=False,
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
