"""mongoengine mirror documents for the admin panel only. These point at the
exact same collections/fields as app/schemas + app/repos (the real async-motor
data layer used by the API) — deliberate, low-risk duplication of field lists
so Starlette-Admin (which needs a sync ODM) doesn't require migrating the
whole API off motor. See plan section 4."""

from datetime import datetime, timezone

import mongoengine as me


class AdminUserDoc(me.Document):
    meta = {"collection": "users"}

    email = me.StringField(required=True)
    username = me.StringField(required=True)
    password_hash = me.StringField(required=True)
    gender = me.StringField(choices=["male", "female"])
    height_cm = me.FloatField()
    weight_kg = me.FloatField()
    age = me.IntField()
    goal = me.StringField()
    activity_level = me.StringField()
    units_metric = me.BooleanField(default=True)
    avatar_seed = me.IntField(default=0)
    role = me.StringField(choices=["user", "admin", "superadmin"], default="user")
    is_banned = me.BooleanField(default=False)
    auth_provider = me.StringField(choices=["local", "google", "apple"], default="local")
    created_at = me.DateTimeField()
    updated_at = me.DateTimeField()

    def __str__(self):
        return f"{self.username} <{self.email}>"


class AdminWeightEntryDoc(me.Document):
    meta = {"collection": "weight_entries"}

    user_id = me.ReferenceField(AdminUserDoc)
    date = me.DateTimeField()
    kg = me.FloatField()
    body_fat_pct = me.FloatField()
    created_at = me.DateTimeField()

    def __str__(self):
        return f"{self.kg}kg on {self.date}"


class AdminMeasurementDoc(me.Document):
    meta = {"collection": "body_measurements"}

    user_id = me.ReferenceField(AdminUserDoc, unique=True)
    zones = me.DictField()
    updated_at = me.DateTimeField()

    def __str__(self):
        return f"Measurements for {self.user_id}"


class AdminTicketMessageDoc(me.EmbeddedDocument):
    sender = me.StringField(choices=["user", "admin"], required=True)
    text = me.StringField(required=True)
    created_at = me.DateTimeField()


class AdminSupportTicketDoc(me.Document):
    meta = {"collection": "support_tickets"}

    user_id = me.ReferenceField(AdminUserDoc)
    username = me.StringField()
    subject = me.StringField()
    status = me.StringField(choices=["open", "closed"], default="open")
    messages = me.EmbeddedDocumentListField(AdminTicketMessageDoc)
    created_at = me.DateTimeField()
    updated_at = me.DateTimeField()

    def __str__(self):
        return f"{self.subject} ({self.status}) — {self.username}"


class AdminAnnouncementDoc(me.Document):
    """Broadcast banners shown to every signed-in user on the dashboard —
    created/edited/deactivated here, fetched by the app via
    GET /api/v1/announcements/active (see app/repos/announcement_repo.py)."""

    meta = {"collection": "announcements"}

    message = me.StringField(required=True, max_length=280)
    active = me.BooleanField(default=True)
    created_at = me.DateTimeField(default=lambda: datetime.now(timezone.utc))
    expires_at = me.DateTimeField(null=True)

    def __str__(self):
        preview = self.message[:40] + ("…" if len(self.message) > 40 else "")
        return f"{preview} ({'active' if self.active else 'inactive'})"
