async def test_add_and_list_weight(client, auth_headers):
    resp = await client.post(
        "/api/v1/weight", headers=auth_headers, json={"kg": 80.5, "bodyFatPct": 15.2}
    )
    assert resp.status_code == 201
    entry = resp.json()
    assert entry["kg"] == 80.5
    assert entry["bodyFatPct"] == 15.2

    resp = await client.get("/api/v1/weight", headers=auth_headers)
    assert resp.status_code == 200
    entries = resp.json()
    assert len(entries) == 1
    assert entries[0]["kg"] == 80.5


async def test_weight_updates_user_profile(client, auth_headers):
    await client.post("/api/v1/weight", headers=auth_headers, json={"kg": 82.0, "bodyFatPct": 14.0})
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.json()["weightKg"] == 82.0


async def test_weight_requires_auth(client):
    resp = await client.get("/api/v1/weight")
    assert resp.status_code == 401
