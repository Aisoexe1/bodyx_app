from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    mongo_uri: str = "mongodb://localhost:27017"
    mongo_db_name: str = "bodyx"

    jwt_secret: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 30  # 30 days

    session_secret: str = "dev-session-secret-change-me"

    # Password reset email delivery via Brevo's HTTPS API. If brevo_api_key
    # is unset, the reset code is logged (and, dev-only, echoed back in the
    # API response) instead of emailed — lets the flow be built/tested before
    # real email delivery is wired up. Raw SMTP was tried first but Render's
    # free tier blocks outbound SMTP traffic; an HTTPS API sidesteps that.
    brevo_api_key: Optional[str] = None
    email_from: str = "BodyX <no-reply@bodyx.app>"
    password_reset_code_ttl_minutes: int = 15

    @property
    def email_configured(self) -> bool:
        return bool(self.brevo_api_key)

    # Google/Apple Sign-In. Unset until the app owner registers real OAuth
    # clients (Google Cloud Console / Apple Developer) — the endpoints
    # return 501 until these are set, rather than silently under-verifying.
    google_client_id: Optional[str] = None
    apple_client_id: Optional[str] = None

    @property
    def google_oauth_configured(self) -> bool:
        return bool(self.google_client_id)

    @property
    def apple_oauth_configured(self) -> bool:
        return bool(self.apple_client_id)


settings = Settings()
