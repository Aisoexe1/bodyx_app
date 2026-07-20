async def test_register_success(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "new@bodyx.dev", "username": "newuser", "password": "secret123"},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["user"]["email"] == "new@bodyx.dev"
    assert body["user"]["username"] == "newuser"
    assert "accessToken" in body
    assert "passwordHash" not in body["user"] and "password" not in body["user"]


async def test_register_password_too_short_422(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "short@bodyx.dev", "username": "shortpw", "password": "ab1"},
    )
    assert resp.status_code == 422


async def test_register_password_no_digit_422(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "nodigit@bodyx.dev", "username": "nodigit", "password": "abcdefgh"},
    )
    assert resp.status_code == 422


async def test_register_password_no_letter_422(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "noletter@bodyx.dev", "username": "noletter", "password": "12345678"},
    )
    assert resp.status_code == 422


async def test_register_password_minimum_valid(client):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "minimum@bodyx.dev", "username": "minimumpw", "password": "ab1234"},
    )
    assert resp.status_code == 201


async def test_register_duplicate_email_409(client, registered_user):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "alex@bodyx.dev", "username": "someoneelse", "password": "secret123"},
    )
    assert resp.status_code == 409


async def test_register_duplicate_username_409(client, registered_user):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": "other@bodyx.dev", "username": "alex", "password": "secret123"},
    )
    assert resp.status_code == 409


async def test_login_success(client, registered_user):
    resp = await client.post(
        "/api/v1/auth/login", json={"email": "alex@bodyx.dev", "password": "secret123"}
    )
    assert resp.status_code == 200
    assert "accessToken" in resp.json()


async def test_login_wrong_password_401(client, registered_user):
    resp = await client.post(
        "/api/v1/auth/login", json={"email": "alex@bodyx.dev", "password": "wrongpass"}
    )
    assert resp.status_code == 401


async def test_me_requires_token_401(client):
    resp = await client.get("/api/v1/users/me")
    assert resp.status_code == 401


async def test_me_with_token(client, auth_headers):
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["email"] == "alex@bodyx.dev"


async def test_banned_user_rejected(client, registered_user, auth_headers):
    import app.database as database_module
    from bson import ObjectId

    db = database_module.get_database()
    await db.users.update_one(
        {"_id": ObjectId(registered_user["user"]["id"])}, {"$set": {"is_banned": True}}
    )
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.status_code == 403

    resp = await client.post(
        "/api/v1/auth/login", json={"email": "alex@bodyx.dev", "password": "secret123"}
    )
    assert resp.status_code == 403


async def test_forgot_password_unknown_email_is_generic(client):
    resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "nobody@bodyx.dev"}
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "message" in body
    assert body.get("devCode") is None


async def test_forgot_password_dev_mode_returns_code(client, registered_user):
    resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"}
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["devCode"] is not None
    assert len(body["devCode"]) == 6


async def test_reset_password_full_round_trip(client, registered_user):
    forgot_resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"}
    )
    code = forgot_resp.json()["devCode"]

    reset_resp = await client.post(
        "/api/v1/auth/reset-password",
        json={"email": "alex@bodyx.dev", "code": code, "newPassword": "newpass123"},
    )
    assert reset_resp.status_code == 200
    assert "accessToken" in reset_resp.json()

    old_login = await client.post(
        "/api/v1/auth/login", json={"email": "alex@bodyx.dev", "password": "secret123"}
    )
    assert old_login.status_code == 401

    new_login = await client.post(
        "/api/v1/auth/login", json={"email": "alex@bodyx.dev", "password": "newpass123"}
    )
    assert new_login.status_code == 200


async def test_reset_password_wrong_code_400(client, registered_user):
    await client.post("/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"})
    resp = await client.post(
        "/api/v1/auth/reset-password",
        json={"email": "alex@bodyx.dev", "code": "000000", "newPassword": "newpass123"},
    )
    assert resp.status_code == 400


async def test_reset_password_code_reuse_rejected(client, registered_user):
    forgot_resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"}
    )
    code = forgot_resp.json()["devCode"]

    first = await client.post(
        "/api/v1/auth/reset-password",
        json={"email": "alex@bodyx.dev", "code": code, "newPassword": "newpass123"},
    )
    assert first.status_code == 200

    second = await client.post(
        "/api/v1/auth/reset-password",
        json={"email": "alex@bodyx.dev", "code": code, "newPassword": "anotherpass1"},
    )
    assert second.status_code == 400


async def test_reset_password_weak_new_password_422(client, registered_user):
    forgot_resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"}
    )
    code = forgot_resp.json()["devCode"]

    resp = await client.post(
        "/api/v1/auth/reset-password",
        json={"email": "alex@bodyx.dev", "code": code, "newPassword": "nodigits"},
    )
    assert resp.status_code == 422


async def test_oauth_google_not_configured_501(client):
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "whatever"})
    assert resp.status_code == 501


async def test_oauth_apple_not_configured_501(client):
    resp = await client.post("/api/v1/auth/oauth/apple", json={"identityToken": "whatever"})
    assert resp.status_code == 501


async def test_oauth_google_creates_new_user(client, monkeypatch):
    monkeypatch.setattr(
        "app.routers.auth.verify_google_id_token",
        lambda token: {"email": "newgoogle@bodyx.dev"},
    )
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "fake-token"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["user"]["email"] == "newgoogle@bodyx.dev"
    assert "accessToken" in body


async def test_oauth_google_logs_in_existing_user_by_email(client, registered_user, monkeypatch):
    monkeypatch.setattr(
        "app.routers.auth.verify_google_id_token",
        lambda token: {"email": "alex@bodyx.dev"},
    )
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "fake-token"})
    assert resp.status_code == 200
    assert resp.json()["user"]["id"] == registered_user["user"]["id"]


async def test_oauth_google_invalid_token_401(client, monkeypatch):
    from app.oauth import OAuthVerificationError

    def raise_err(token):
        raise OAuthVerificationError("bad signature")

    monkeypatch.setattr("app.routers.auth.verify_google_id_token", raise_err)
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "fake-token"})
    assert resp.status_code == 401


async def test_oauth_apple_creates_new_user(client, monkeypatch):
    monkeypatch.setattr(
        "app.routers.auth.verify_apple_identity_token",
        lambda token: {"email": "newapple@bodyx.dev"},
    )
    resp = await client.post("/api/v1/auth/oauth/apple", json={"identityToken": "fake-token"})
    assert resp.status_code == 200
    assert resp.json()["user"]["email"] == "newapple@bodyx.dev"


async def test_oauth_banned_user_rejected(client, registered_user, monkeypatch):
    import app.database as database_module
    from bson import ObjectId

    db = database_module.get_database()
    await db.users.update_one(
        {"_id": ObjectId(registered_user["user"]["id"])}, {"$set": {"is_banned": True}}
    )
    monkeypatch.setattr(
        "app.routers.auth.verify_google_id_token",
        lambda token: {"email": "alex@bodyx.dev"},
    )
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "fake-token"})
    assert resp.status_code == 403


async def test_oauth_username_collision_gets_disambiguated(client, registered_user, monkeypatch):
    # registered_user already owns username "alex" — a new Google account
    # deriving the same base username from its email must not collide.
    monkeypatch.setattr(
        "app.routers.auth.verify_google_id_token",
        lambda token: {"email": "alex@gmail.com"},
    )
    resp = await client.post("/api/v1/auth/oauth/google", json={"idToken": "fake-token"})
    assert resp.status_code == 200
    assert resp.json()["user"]["username"] != "alex"


async def test_delete_me_removes_account_and_data(client, registered_user, auth_headers):
    import app.database as database_module
    from bson import ObjectId

    db = database_module.get_database()
    user_id = ObjectId(registered_user["user"]["id"])

    # Give the account a weight entry and a measurement so the cascade has
    # something real to remove, not just the user document.
    resp = await client.post("/api/v1/weight", json={"kg": 80, "bodyFatPct": 15}, headers=auth_headers)
    assert resp.status_code == 201
    resp = await client.put(
        "/api/v1/measurements",
        json={"chest": {"valueCm": 100, "targetCm": 105}},
        headers=auth_headers,
    )
    assert resp.status_code == 200

    resp = await client.delete("/api/v1/users/me", headers=auth_headers)
    assert resp.status_code == 204

    assert await db.users.find_one({"_id": user_id}) is None
    assert await db.weight_entries.find_one({"user_id": user_id}) is None
    assert await db.body_measurements.find_one({"user_id": user_id}) is None

    # The token must no longer authenticate anything — the account is gone.
    resp = await client.get("/api/v1/users/me", headers=auth_headers)
    assert resp.status_code == 401


async def test_delete_me_requires_token_401(client):
    resp = await client.delete("/api/v1/users/me")
    assert resp.status_code == 401
