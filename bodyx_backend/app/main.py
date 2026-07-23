from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from limits import RateLimitItemPerMinute
from limits.storage import MemoryStorage
from limits.strategies import FixedWindowRateLimiter
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address
from starlette.middleware.base import BaseHTTPMiddleware

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


# No third-party API consumers exist for this mobile-app backend — the
# interactive docs just hand an unauthenticated caller a full map of every
# route/schema for free. Disabled outright rather than gated behind a
# debug flag, since nothing in this codebase has ever relied on them.
app = FastAPI(
    title="BodyX API",
    version="0.1.0",
    lifespan=lifespan,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """No reverse proxy/CDN fronts this app in its own deployment (bare
    uvicorn — see docker-compose.yml) — these headers have to come from the
    app itself or nothing ever sets them. Matters most for the admin panel,
    a real cookie-authenticated browser UI with ban/delete/role-change
    actions, not just the JSON API. Only frame-ancestors is set (not a full
    CSP) so this can't accidentally break the admin UI's own inline
    scripts/styles, which no other directive here restricts."""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Content-Security-Policy"] = "frame-ancestors 'none'"
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
        return response


# slowapi's route-based limiting can't see anything mounted as a Starlette
# `Mount` (see app/rate_limit.py's docstring for why) — Starlette-Admin's
# own /admin/login is exactly that, so the @limiter.limit(...) decorators on
# the consumer /auth/login never apply to it despite checking a password
# against the very same users collection (app/admin/auth.py). This is a
# second, independent limiter using the same underlying `limits` library
# slowapi wraps, applied by matching the path directly instead of by route
# object, since that's the one thing a Mount can't hide from.
_admin_login_limit_storage = MemoryStorage()
_admin_login_limiter = FixedWindowRateLimiter(_admin_login_limit_storage)
_admin_login_rate_limit = RateLimitItemPerMinute(5)


class AdminLoginRateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/admin/login" and request.method == "POST":
            key = get_remote_address(request)
            if limiter.enabled and not _admin_login_limiter.hit(
                _admin_login_rate_limit, key
            ):
                return JSONResponse(
                    {"detail": "Too many login attempts, try again shortly"},
                    status_code=429,
                )
        return await call_next(request)


app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(AdminLoginRateLimitMiddleware)

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
