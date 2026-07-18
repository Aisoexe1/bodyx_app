from starlette.requests import Request
from starlette.responses import Response
from starlette_admin.auth import AdminUser, AuthProvider
from starlette_admin.exceptions import LoginFailed

from app.admin.models import AdminUserDoc
from app.security import verify_password

_ROLE_PERMISSIONS = {
    "admin": ["view_users", "ban_users", "delete_users"],
    "superadmin": ["view_users", "ban_users", "delete_users", "manage_roles"],
}


class AdminAuthProvider(AuthProvider):
    async def login(
        self,
        username: str,
        password: str,
        remember_me: bool,
        request: Request,
        response: Response,
    ) -> Response:
        user = AdminUserDoc.objects(email=username.lower()).first() or AdminUserDoc.objects(
            username=username
        ).first()

        if user is None or not verify_password(password, user.password_hash):
            raise LoginFailed("Invalid email/username or password")

        if user.role not in _ROLE_PERMISSIONS:
            raise LoginFailed("This account does not have admin access")

        if user.is_banned:
            raise LoginFailed("This account has been banned")

        request.session.update({"user_id": str(user.id)})
        return response

    async def is_authenticated(self, request: Request) -> bool:
        user_id = request.session.get("user_id")
        if not user_id:
            return False

        user = AdminUserDoc.objects(id=user_id).first()
        if user is None or user.role not in _ROLE_PERMISSIONS or user.is_banned:
            return False

        request.state.user = {
            "id": str(user.id),
            "name": user.username,
            "role": user.role,
            "roles": _ROLE_PERMISSIONS[user.role],
        }
        return True

    def get_admin_user(self, request: Request) -> AdminUser:
        return AdminUser(username=request.state.user["name"])

    async def logout(self, request: Request, response: Response) -> Response:
        request.session.clear()
        return response
