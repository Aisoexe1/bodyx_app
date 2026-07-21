from datetime import datetime, timezone
from typing import Any

from starlette.requests import Request
from starlette_admin import row_action
from starlette_admin.contrib.mongoengine import ModelView
from starlette_admin.exceptions import ActionFailed

from app.admin.models import (
    AdminAnnouncementDoc,
    AdminMeasurementDoc,
    AdminSupportTicketDoc,
    AdminTicketMessageDoc,
    AdminUserDoc,
    AdminWeightEntryDoc,
)

_VALID_ROLES = ("user", "admin", "superadmin")


class UserAdminView(ModelView):
    fields = [
        "id",
        "email",
        "username",
        "role",
        "is_banned",
        "auth_provider",
        "gender",
        "height_cm",
        "weight_kg",
        "age",
        "created_at",
    ]
    exclude_fields_from_create = ["role"]
    exclude_fields_from_edit = ["role", "password_hash", "auth_provider"]
    row_actions = ["view", "edit", "toggle_ban", "change_role", "delete_cascade"]

    def can_create(self, request: Request) -> bool:
        return False

    def can_delete(self, request: Request) -> bool:
        # deletion only via the delete_cascade row action, to keep weight/measurement data consistent
        return False

    async def is_row_action_allowed(self, request: Request, name: str) -> bool:
        roles = request.state.user.get("roles", [])
        if name == "toggle_ban":
            return "ban_users" in roles
        if name == "delete_cascade":
            return "delete_users" in roles
        if name == "change_role":
            return "manage_roles" in roles
        return await super().is_row_action_allowed(request, name)

    @row_action(
        name="toggle_ban",
        text="Ban / Unban",
        confirmation="Toggle this user's banned status?",
        icon_class="fas fa-ban",
        submit_btn_text="Confirm",
        submit_btn_class="btn-warning",
    )
    async def toggle_ban_action(self, request: Request, pk: Any) -> str:
        user = AdminUserDoc.objects(id=pk).first()
        if user is None:
            raise ActionFailed("User not found")
        user.is_banned = not user.is_banned
        user.save()
        return f"User is now {'banned' if user.is_banned else 'unbanned'}"

    @row_action(
        name="change_role",
        text="Change role",
        confirmation="Set a new role for this user",
        icon_class="fas fa-user-shield",
        submit_btn_text="Save",
        submit_btn_class="btn-primary",
        form="""
        <form>
            <div class="mt-3">
                <select class="form-select" name="role">
                    <option value="user">user</option>
                    <option value="admin">admin</option>
                    <option value="superadmin">superadmin</option>
                </select>
            </div>
        </form>
        """,
    )
    async def change_role_action(self, request: Request, pk: Any) -> str:
        data = await request.form()
        new_role = data.get("role")
        if new_role not in _VALID_ROLES:
            raise ActionFailed("Invalid role")
        user = AdminUserDoc.objects(id=pk).first()
        if user is None:
            raise ActionFailed("User not found")
        user.role = new_role
        user.save()
        return f"Role updated to {new_role}"

    @row_action(
        name="delete_cascade",
        text="Delete user",
        confirmation="Delete this user AND all their weight/measurement data? This cannot be undone.",
        icon_class="fas fa-trash",
        submit_btn_text="Delete",
        submit_btn_class="btn-danger",
    )
    async def delete_cascade_action(self, request: Request, pk: Any) -> str:
        user = AdminUserDoc.objects(id=pk).first()
        if user is None:
            raise ActionFailed("User not found")
        AdminWeightEntryDoc.objects(user_id=user.id).delete()
        AdminMeasurementDoc.objects(user_id=user.id).delete()
        user.delete()
        return "User and all associated data deleted"


class ReadOnlyView(ModelView):
    """Shared base: list/view only, no create/edit/delete."""

    def can_create(self, request: Request) -> bool:
        return False

    def can_edit(self, request: Request) -> bool:
        return False

    def can_delete(self, request: Request) -> bool:
        return False


class AnnouncementAdminView(ModelView):
    fields = ["id", "message", "active", "created_at", "expires_at"]
    exclude_fields_from_create = ["created_at"]
    exclude_fields_from_edit = ["created_at"]


class WeightEntryAdminView(ReadOnlyView):
    fields = ["id", "user_id", "date", "kg", "body_fat_pct", "created_at"]


class MeasurementAdminView(ReadOnlyView):
    fields = ["id", "user_id", "zones", "updated_at"]


class SupportTicketAdminView(ModelView):
    fields = ["id", "username", "subject", "status", "messages", "created_at", "updated_at"]
    exclude_fields_from_list = ["messages"]
    row_actions = ["view", "reply", "close", "delete"]

    def can_create(self, request: Request) -> bool:
        return False

    def can_edit(self, request: Request) -> bool:
        # Mutations only via the reply/close row actions below, so every
        # change is an explicit, auditable action rather than a raw field edit.
        return False

    @row_action(
        name="reply",
        text="Reply",
        # Starlette-Admin only renders the row action's modal (and thus this
        # form) when `confirmation` is set — without it, the action fires
        # immediately with an empty body instead of showing the reply box.
        confirmation="Write your reply below.",
        icon_class="fas fa-reply",
        submit_btn_text="Send",
        submit_btn_class="btn-primary",
        form="""
        <form>
            <div class="mt-3">
                <textarea class="form-control" name="reply_text" rows="4"
                    placeholder="Your reply..." required></textarea>
            </div>
            <div class="form-check mt-2">
                <input class="form-check-input" type="checkbox" name="close_after"
                    value="yes" checked>
                <label class="form-check-label">Close ticket after replying</label>
            </div>
        </form>
        """,
    )
    async def reply_action(self, request: Request, pk: Any) -> str:
        data = await request.form()
        text = (data.get("reply_text") or "").strip()
        if not text:
            raise ActionFailed("Reply text is required")

        ticket = AdminSupportTicketDoc.objects(id=pk).first()
        if ticket is None:
            raise ActionFailed("Ticket not found")

        now = datetime.now(timezone.utc)
        ticket.messages.append(
            AdminTicketMessageDoc(sender="admin", text=text, created_at=now)
        )
        ticket.status = "closed" if data.get("close_after") else "open"
        ticket.updated_at = now
        ticket.save()
        return "Reply sent" + (" and ticket closed" if ticket.status == "closed" else "")

    @row_action(
        name="close",
        text="Close",
        confirmation="Close this ticket without sending a reply?",
        icon_class="fas fa-check",
        submit_btn_text="Close",
        submit_btn_class="btn-success",
    )
    async def close_action(self, request: Request, pk: Any) -> str:
        ticket = AdminSupportTicketDoc.objects(id=pk).first()
        if ticket is None:
            raise ActionFailed("Ticket not found")
        ticket.status = "closed"
        ticket.updated_at = datetime.now(timezone.utc)
        ticket.save()
        return "Ticket closed"
