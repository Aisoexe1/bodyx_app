import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from mongomock_motor import AsyncMongoMockClient

import app.database as database_module
from app.config import settings
from app.main import app


@pytest.fixture(autouse=True)
def _force_dev_mode_email(monkeypatch):
    """The test suite must behave the same regardless of what email creds a
    developer happens to have in their local .env — force dev-mode (no real
    send, code echoed back) so forgot-password tests stay deterministic."""
    monkeypatch.setattr(settings, "brevo_api_key", None)


@pytest_asyncio.fixture
async def client():
    """Points the app's Mongo client at an in-memory mongomock instance for
    the duration of the test, so tests never touch the real (Atlas) database."""
    database_module._client = AsyncMongoMockClient()
    await database_module.ensure_indexes()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    database_module._client = None


@pytest_asyncio.fixture
async def registered_user(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "alex@bodyx.dev", "username": "alex", "password": "secret123"},
    )
    assert resp.status_code == 201
    body = resp.json()
    return {"token": body["accessToken"], "user": body["user"]}


@pytest_asyncio.fixture
async def auth_headers(registered_user):
    return {"Authorization": f"Bearer {registered_user['token']}"}
