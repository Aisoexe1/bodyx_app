from app.rate_limit import limiter


async def test_login_is_rate_limited(client, registered_user):
    """Confirms the limiter actually blocks, not just that it's wired up —
    re-enables it just for this test (conftest.py's autouse fixture disables
    it everywhere else so the rest of the suite isn't tripped by repeated
    /register calls sharing one test-client "IP")."""
    limiter.enabled = True
    try:
        last_status = None
        for _ in range(11):  # login is limited to 10/minute
            resp = await client.post(
                "/api/v1/auth/login",
                json={"email": "alex@bodyx.dev", "password": "wrong-password"},
            )
            last_status = resp.status_code
        assert last_status == 429
    finally:
        limiter.enabled = False
        limiter.reset()


async def test_reset_password_code_locks_out_after_max_attempts(client, registered_user):
    """password_reset_repo.MAX_ATTEMPTS wrong guesses against a real,
    unexpired code should burn its budget — the next attempt must fail even
    though the code itself was never actually used successfully, closing
    the brute-force-the-6-digit-code gap independent of any rate limiting."""
    forgot_resp = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "alex@bodyx.dev"}
    )
    assert forgot_resp.status_code == 200
    real_code = forgot_resp.json()["devCode"]
    wrong_code = "000000" if real_code != "000000" else "111111"

    for _ in range(5):  # MAX_ATTEMPTS
        resp = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "email": "alex@bodyx.dev",
                "code": wrong_code,
                "newPassword": "irrelevant1",
            },
        )
        assert resp.status_code == 400

    # The budget is now exhausted — even the *correct* code must be rejected.
    resp = await client.post(
        "/api/v1/auth/reset-password",
        json={
            "email": "alex@bodyx.dev",
            "code": real_code,
            "newPassword": "newpassword1",
        },
    )
    assert resp.status_code == 400
