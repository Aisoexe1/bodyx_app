from app.oauth import _is_email_verified


def test_missing_claim_treated_as_verified():
    # Not every provider/flow always includes the claim — absence isn't
    # the same as an explicit false, so this must not reject it.
    assert _is_email_verified({}) is True


def test_explicit_bool_true():
    assert _is_email_verified({"email_verified": True}) is True


def test_explicit_bool_false():
    assert _is_email_verified({"email_verified": False}) is False


def test_apple_style_string_true():
    # Apple's SDKs are documented to send this as the string "true", not
    # a real JSON boolean.
    assert _is_email_verified({"email_verified": "true"}) is True


def test_apple_style_string_false():
    assert _is_email_verified({"email_verified": "false"}) is False
