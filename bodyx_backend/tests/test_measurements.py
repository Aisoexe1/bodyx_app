async def test_get_measurements_auto_seeds(client, auth_headers):
    resp = await client.get("/api/v1/measurements", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "chest" in data
    assert len(data) == 10
    assert len(data["chest"]["history"]) == 6


async def test_patch_zone_appends_history(client, auth_headers):
    before = (await client.get("/api/v1/measurements", headers=auth_headers)).json()
    before_len = len(before["chest"]["history"])

    resp = await client.patch(
        "/api/v1/measurements/chest", headers=auth_headers, json={"valueCm": 106.2}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["chest"]["valueCm"] == 106.2
    assert len(data["chest"]["history"]) == before_len + 1
    assert data["chest"]["history"][-1] == 106.2


async def test_put_replaces_measurements(client, auth_headers):
    current = (await client.get("/api/v1/measurements", headers=auth_headers)).json()
    current["chest"]["valueCm"] = 999.0

    resp = await client.put("/api/v1/measurements", headers=auth_headers, json=current)
    assert resp.status_code == 200
    assert resp.json()["chest"]["valueCm"] == 999.0


async def test_measurements_requires_auth(client):
    resp = await client.get("/api/v1/measurements")
    assert resp.status_code == 401
