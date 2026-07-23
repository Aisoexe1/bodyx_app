from pathlib import Path

import mongoengine as me
from starlette.middleware import Middleware
from starlette.middleware.sessions import SessionMiddleware
from starlette_admin.contrib.mongoengine import Admin

from app.admin.auth import AdminAuthProvider
from app.admin.dashboard import AnalyticsDashboard
from app.admin.models import (
    AdminAnnouncementDoc,
    AdminMeasurementDoc,
    AdminSupportTicketDoc,
    AdminUserDoc,
    AdminWeightEntryDoc,
)
from app.admin.views import (
    AnnouncementAdminView,
    MeasurementAdminView,
    SupportTicketAdminView,
    UserAdminView,
    WeightEntryAdminView,
)
from app.config import settings

_TEMPLATES_DIR = str(Path(__file__).parent / "templates")

_mongoengine_connected = False


def _ensure_mongoengine_connected() -> None:
    global _mongoengine_connected
    if _mongoengine_connected:
        return
    me.connect(db=settings.mongo_db_name, host=settings.mongo_uri)
    _mongoengine_connected = True


def build_admin() -> Admin:
    _ensure_mongoengine_connected()

    admin = Admin(
        title="BodyX Admin",
        auth_provider=AdminAuthProvider(),
        middlewares=[
            Middleware(
                SessionMiddleware,
                secret_key=settings.session_secret,
                # Starlette's defaults (https_only=False, same_site="lax")
                # would let this session cookie — the sole credential
                # gating ban/delete/role-change — ride over a plain HTTP
                # connection and be attached to more cross-site contexts
                # than this admin-only, same-origin cookie needs. Browsers
                # treat 127.0.0.1/localhost as a secure context, so
                # https_only=True doesn't break local dev over plain http.
                https_only=True,
                same_site="strict",
                # There's no server-side session store logout can actually
                # delete from (request.session.clear() only erases the
                # browser's own copy) — Starlette's 14-day default max_age
                # would let a copied/leaked cookie outlive that for two
                # weeks regardless. A shorter TTL isn't real revocation,
                # but it bounds the same class of exposure the JWT
                # token_version fix (app/security.py) closes properly.
                max_age=60 * 60 * 12,
            )
        ],
        templates_dir=_TEMPLATES_DIR,
        index_view=AnalyticsDashboard(),
    )

    admin.add_view(UserAdminView(AdminUserDoc, icon="fas fa-users", label="Users"))
    admin.add_view(
        WeightEntryAdminView(AdminWeightEntryDoc, icon="fas fa-weight", label="Weight Entries")
    )
    admin.add_view(
        MeasurementAdminView(AdminMeasurementDoc, icon="fas fa-ruler", label="Measurements")
    )
    admin.add_view(
        SupportTicketAdminView(
            AdminSupportTicketDoc, icon="fas fa-life-ring", label="Support Tickets"
        )
    )
    admin.add_view(
        AnnouncementAdminView(
            AdminAnnouncementDoc, icon="fas fa-bullhorn", label="Announcements"
        )
    )

    return admin
