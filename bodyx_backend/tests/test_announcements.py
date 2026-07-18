from datetime import datetime, timedelta, timezone

import app.database as database_module


async def _insert_announcement(**overrides):
    db = database_module.get_database()
    doc = {
        "message": "Scheduled maintenance tonight",
        "active": True,
        "created_at": datetime.now(timezone.utc),
        "expires_at": None,
        **overrides,
    }
    await db.announcements.insert_one(doc)


async def test_list_active_returns_active_announcement(client, auth_headers):
    await _insert_announcement()

    resp = await client.get("/api/v1/announcements/active", headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert len(body) == 1
    assert body[0]["message"] == "Scheduled maintenance tonight"


async def test_list_active_excludes_inactive(client, auth_headers):
    await _insert_announcement(active=False)

    resp = await client.get("/api/v1/announcements/active", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


async def test_list_active_excludes_expired(client, auth_headers):
    await _insert_announcement(expires_at=datetime.now(timezone.utc) - timedelta(days=1))

    resp = await client.get("/api/v1/announcements/active", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


async def test_list_active_includes_not_yet_expired(client, auth_headers):
    await _insert_announcement(expires_at=datetime.now(timezone.utc) + timedelta(days=1))

    resp = await client.get("/api/v1/announcements/active", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 1


async def test_list_active_requires_auth(client):
    resp = await client.get("/api/v1/announcements/active")
    assert resp.status_code == 401


async def test_list_active_newest_first(client, auth_headers):
    now = datetime.now(timezone.utc)
    await _insert_announcement(message="Older", created_at=now - timedelta(hours=1))
    await _insert_announcement(message="Newer", created_at=now)

    resp = await client.get("/api/v1/announcements/active", headers=auth_headers)
    messages = [a["message"] for a in resp.json()]
    assert messages == ["Newer", "Older"]
