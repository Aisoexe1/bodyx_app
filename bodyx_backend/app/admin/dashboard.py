from datetime import datetime, timedelta, timezone

from starlette.requests import Request
from starlette.responses import Response
from starlette_admin.views import CustomView

from app.admin.models import AdminSupportTicketDoc, AdminUserDoc, AdminWeightEntryDoc


def _format_duration(seconds: float) -> str:
    seconds = int(seconds)
    if seconds < 3600:
        return f"{max(seconds // 60, 1)}m"
    hours = seconds // 3600
    if hours < 48:
        return f"{hours}h"
    return f"{hours // 24}d"


class AnalyticsDashboard(CustomView):
    def __init__(self):
        super().__init__(
            label="Dashboard",
            icon="fas fa-chart-line",
            path="/",
            template_path="dashboard.html",
            name="dashboard",
            add_to_menu=False,
        )

    async def render(self, request: Request, templates) -> Response:
        now = datetime.now(timezone.utc)
        week_ago = now - timedelta(days=7)

        stats = {
            "total_users": AdminUserDoc.objects.count(),
            "new_users_7d": AdminUserDoc.objects(created_at__gte=week_ago).count(),
            "banned_users": AdminUserDoc.objects(is_banned=True).count(),
            "total_weight_entries": AdminWeightEntryDoc.objects.count(),
        }

        # Registrations per day, last 14 days — oldest first so the bars read left-to-right.
        daily_signups = []
        for i in range(13, -1, -1):
            day_start = (now - timedelta(days=i)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            day_end = day_start + timedelta(days=1)
            count = AdminUserDoc.objects(
                created_at__gte=day_start, created_at__lt=day_end
            ).count()
            daily_signups.append({"label": day_start.strftime("%b %d"), "count": count})
        max_daily_signups = max((d["count"] for d in daily_signups), default=0) or 1

        provider_stats = {
            "local": AdminUserDoc.objects(auth_provider="local").count(),
            "google": AdminUserDoc.objects(auth_provider="google").count(),
            "apple": AdminUserDoc.objects(auth_provider="apple").count(),
        }

        open_tickets = AdminSupportTicketDoc.objects(status="open").count()
        closed_tickets = AdminSupportTicketDoc.objects(status="closed").count()

        response_seconds = []
        for ticket in AdminSupportTicketDoc.objects.only("messages"):
            first_user = next((m for m in ticket.messages if m.sender == "user"), None)
            first_admin = next((m for m in ticket.messages if m.sender == "admin"), None)
            if (
                first_user is not None
                and first_admin is not None
                and first_admin.created_at > first_user.created_at
            ):
                response_seconds.append(
                    (first_admin.created_at - first_user.created_at).total_seconds()
                )

        ticket_stats = {
            "open": open_tickets,
            "closed": closed_tickets,
            "total": open_tickets + closed_tickets,
            "avg_response": (
                _format_duration(sum(response_seconds) / len(response_seconds))
                if response_seconds
                else "—"
            ),
            "answered_count": len(response_seconds),
        }

        return templates.TemplateResponse(
            request=request,
            name=self.template_path,
            context={
                "title": "Dashboard",
                "stats": stats,
                "daily_signups": daily_signups,
                "max_daily_signups": max_daily_signups,
                "provider_stats": provider_stats,
                "ticket_stats": ticket_stats,
            },
        )
