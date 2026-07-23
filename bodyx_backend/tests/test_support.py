async def test_create_ticket(client, auth_headers):
    resp = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Can't log a meal", "message": "The save button does nothing."},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["subject"] == "Can't log a meal"
    assert body["status"] == "open"
    assert len(body["messages"]) == 1
    assert body["messages"][0]["sender"] == "user"
    assert body["messages"][0]["text"] == "The save button does nothing."
    assert body["username"] == "alex"


async def test_create_ticket_requires_auth(client):
    resp = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Hello", "message": "Hi"},
    )
    assert resp.status_code == 401


async def test_create_ticket_validation(client, auth_headers):
    resp = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "", "message": "Hi"},
        headers=auth_headers,
    )
    assert resp.status_code == 422


async def test_list_tickets_only_returns_own(client, auth_headers):
    await client.post(
        "/api/v1/support/tickets",
        json={"subject": "First", "message": "One"},
        headers=auth_headers,
    )
    await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Second", "message": "Two"},
        headers=auth_headers,
    )

    other = await client.post(
        "/api/v1/auth/register",
        json={"email": "other@bodyx.dev", "username": "other", "password": "secret123"},
    )
    other_headers = {"Authorization": f"Bearer {other.json()['accessToken']}"}
    await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Not mine", "message": "Shouldn't show up"},
        headers=other_headers,
    )

    resp = await client.get("/api/v1/support/tickets", headers=auth_headers)
    assert resp.status_code == 200
    subjects = {t["subject"] for t in resp.json()}
    assert subjects == {"First", "Second"}


async def test_get_ticket_succeeds_for_owner(client, auth_headers):
    created = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Mine", "message": "Body"},
        headers=auth_headers,
    )
    ticket_id = created.json()["id"]

    resp = await client.get(f"/api/v1/support/tickets/{ticket_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["subject"] == "Mine"


async def test_get_ticket_not_found_for_other_user(client, auth_headers):
    created = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Mine", "message": "Body"},
        headers=auth_headers,
    )
    ticket_id = created.json()["id"]

    other = await client.post(
        "/api/v1/auth/register",
        json={"email": "other2@bodyx.dev", "username": "other2", "password": "secret123"},
    )
    other_headers = {"Authorization": f"Bearer {other.json()['accessToken']}"}

    resp = await client.get(f"/api/v1/support/tickets/{ticket_id}", headers=other_headers)
    assert resp.status_code == 404


async def test_add_message_appends_and_stays_open(client, auth_headers):
    created = await client.post(
        "/api/v1/support/tickets",
        json={"subject": "Mine", "message": "Body"},
        headers=auth_headers,
    )
    ticket_id = created.json()["id"]

    resp = await client.post(
        f"/api/v1/support/tickets/{ticket_id}/messages",
        json={"text": "Any update?"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["messages"]) == 2
    assert body["messages"][1]["text"] == "Any update?"
    assert body["status"] == "open"


async def test_add_message_not_found_404(client, auth_headers):
    resp = await client.post(
        "/api/v1/support/tickets/000000000000000000000000/messages",
        json={"text": "Hello?"},
        headers=auth_headers,
    )
    assert resp.status_code == 404
