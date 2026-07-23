async def test_pet_xp_defaults_to_zero(client, auth_headers):
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["petXp"] == 0


async def test_updating_pet_xp_persists(client, auth_headers):
    resp = await client.patch(
        "/api/v1/users/me", headers=auth_headers, json={"petXp": 250}
    )
    assert resp.status_code == 200
    assert resp.json()["petXp"] == 250

    # Round-trips back on a fresh fetch too, not just the PATCH response.
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.json()["petXp"] == 250


async def test_negative_pet_xp_is_rejected(client, auth_headers):
    resp = await client.patch(
        "/api/v1/users/me", headers=auth_headers, json={"petXp": -1}
    )
    assert resp.status_code == 422


async def test_updating_pet_xp_does_not_disturb_other_fields(client, auth_headers):
    await client.patch("/api/v1/users/me", headers=auth_headers, json={"goal": "Lose weight"})
    resp = await client.patch(
        "/api/v1/users/me", headers=auth_headers, json={"petXp": 100}
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["petXp"] == 100
    assert body["goal"] == "Lose weight"
