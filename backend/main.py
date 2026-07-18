"""BodyX backend — implements exactly the contract the Flutter client's
lib/network/ layer already speaks (see the repo's API docs / Obsidian vault).

Design goals, in order: correctness against the client contract, zero
infrastructure assumptions (SQLite file next to the code), and easy
deployment to any free-tier host (Render/Railway/Fly) via the Dockerfile.

Auth: JWT bearer tokens (HS256). Passwords stored as PBKDF2-HMAC-SHA256.
Password reset: 6-digit code; without SMTP configured the code is echoed
back in the response as `devCode` — the client displays it in dev builds.
This is an intentional dev-only convenience: set SMTP_* env vars (or just
DISABLE_DEV_CODE=1) in production to turn it off.
"""

import base64
import hashlib
import hmac
import json
import os
import secrets
import sqlite3
import time
from contextlib import contextmanager
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

DB_PATH = os.environ.get("BODYX_DB", os.path.join(os.path.dirname(__file__), "bodyx.db"))
JWT_SECRET = os.environ.get("JWT_SECRET") or secrets.token_hex(32)
JWT_TTL_SECONDS = int(os.environ.get("JWT_TTL_SECONDS", 60 * 60 * 24 * 30))  # 30 days
DISABLE_DEV_CODE = os.environ.get("DISABLE_DEV_CODE") == "1"
RESET_CODE_TTL = 15 * 60

app = FastAPI(title="BodyX API", docs_url="/api/v1/docs", openapi_url="/api/v1/openapi.json")

MUSCLE_ZONES = [
    "shoulders", "chest", "biceps", "forearms", "abs",
    "quads", "calves", "back", "glutes", "hamstrings",
]

# ---- storage ---------------------------------------------------------------


@contextmanager
def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with db() as c:
        c.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                email TEXT NOT NULL UNIQUE COLLATE NOCASE,
                username TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                name TEXT NOT NULL DEFAULT '',
                gender TEXT NOT NULL DEFAULT 'male',
                height_cm REAL NOT NULL DEFAULT 175,
                weight_kg REAL NOT NULL DEFAULT 75,
                age INTEGER NOT NULL DEFAULT 25,
                goal TEXT NOT NULL DEFAULT 'Build muscle',
                activity_level TEXT NOT NULL DEFAULT 'Moderately active',
                units_metric INTEGER NOT NULL DEFAULT 1,
                avatar_seed INTEGER NOT NULL DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS weight_entries (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                date TEXT NOT NULL,
                kg REAL NOT NULL,
                body_fat_pct REAL NOT NULL
            );
            CREATE TABLE IF NOT EXISTS measurements (
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                zone TEXT NOT NULL,
                value_cm REAL NOT NULL,
                target_cm REAL NOT NULL,
                history TEXT NOT NULL DEFAULT '[]',
                PRIMARY KEY (user_id, zone)
            );
            CREATE TABLE IF NOT EXISTS reset_codes (
                email TEXT PRIMARY KEY COLLATE NOCASE,
                code TEXT NOT NULL,
                expires_at INTEGER NOT NULL
            );
            """
        )


init_db()

# ---- passwords / tokens ----------------------------------------------------


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 200_000)
    return f"{base64.b64encode(salt).decode()}${base64.b64encode(digest).decode()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        salt_b64, digest_b64 = stored.split("$", 1)
        salt = base64.b64decode(salt_b64)
        expected = base64.b64decode(digest_b64)
    except (ValueError, TypeError):
        return False
    actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 200_000)
    return hmac.compare_digest(actual, expected)


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _b64url_decode(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def make_token(user_id: int) -> str:
    header = _b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    payload = _b64url(json.dumps({"sub": str(user_id), "exp": int(time.time()) + JWT_TTL_SECONDS}).encode())
    signature = _b64url(hmac.new(JWT_SECRET.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
    return f"{header}.{payload}.{signature}"


def read_token(token: str) -> Optional[int]:
    try:
        header, payload, signature = token.split(".")
        expected = _b64url(hmac.new(JWT_SECRET.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(signature, expected):
            return None
        claims = json.loads(_b64url_decode(payload))
        if claims.get("exp", 0) < time.time():
            return None
        return int(claims["sub"])
    except (ValueError, KeyError, TypeError):
        return None


def current_user_id(request: Request) -> int:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(401, "Not authenticated")
    user_id = read_token(auth[7:])
    if user_id is None:
        raise HTTPException(401, "Invalid or expired token")
    with db() as c:
        if c.execute("SELECT 1 FROM users WHERE id = ?", (user_id,)).fetchone() is None:
            raise HTTPException(401, "Account no longer exists")
    return user_id


# ---- serialization matching the Flutter client exactly ---------------------


def user_json(row: sqlite3.Row) -> dict:
    return {
        "email": row["email"],
        "username": row["username"],
        "name": row["name"] or row["username"],
        "gender": row["gender"],
        "heightCm": row["height_cm"],
        "weightKg": row["weight_kg"],
        "age": row["age"],
        "goal": row["goal"],
        "activityLevel": row["activity_level"],
        "unitsMetric": bool(row["units_metric"]),
        "avatarSeed": row["avatar_seed"],
    }


def auth_response(c: sqlite3.Connection, user_id: int) -> dict:
    row = c.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    return {"accessToken": make_token(user_id), "user": user_json(row)}


# ---- request models --------------------------------------------------------


class RegisterBody(BaseModel):
    email: str = Field(min_length=3)
    username: str = Field(min_length=1)
    password: str = Field(min_length=6)


class LoginBody(BaseModel):
    email: str
    password: str


class ForgotBody(BaseModel):
    email: str


class ResetBody(BaseModel):
    email: str
    code: str
    newPassword: str = Field(min_length=6)


class PatchMeBody(BaseModel):
    username: Optional[str] = None
    name: Optional[str] = None
    gender: Optional[str] = None
    heightCm: Optional[float] = None
    weightKg: Optional[float] = None
    age: Optional[int] = None
    goal: Optional[str] = None
    activityLevel: Optional[str] = None
    unitsMetric: Optional[bool] = None
    avatarSeed: Optional[int] = None


class WeightBody(BaseModel):
    kg: float
    bodyFatPct: float


class ZonePatchBody(BaseModel):
    valueCm: float


# ---- auth endpoints --------------------------------------------------------


@app.post("/api/v1/auth/register")
def register(body: RegisterBody):
    with db() as c:
        if c.execute("SELECT 1 FROM users WHERE email = ?", (body.email.strip(),)).fetchone():
            raise HTTPException(409, "An account with this email already exists")
        cur = c.execute(
            "INSERT INTO users (email, username, password_hash, name) VALUES (?, ?, ?, ?)",
            (body.email.strip(), body.username.strip(), hash_password(body.password), body.username.strip()),
        )
        return auth_response(c, cur.lastrowid)


@app.post("/api/v1/auth/login")
def login(body: LoginBody):
    with db() as c:
        row = c.execute("SELECT * FROM users WHERE email = ?", (body.email.strip(),)).fetchone()
        if row is None or not verify_password(body.password, row["password_hash"]):
            raise HTTPException(401, "Incorrect email or password")
        return auth_response(c, row["id"])


@app.post("/api/v1/auth/forgot-password")
def forgot_password(body: ForgotBody):
    with db() as c:
        row = c.execute("SELECT 1 FROM users WHERE email = ?", (body.email.strip(),)).fetchone()
        # Do not reveal whether the email exists — always behave identically.
        code = f"{secrets.randbelow(1_000_000):06d}"
        if row:
            c.execute(
                "INSERT OR REPLACE INTO reset_codes (email, code, expires_at) VALUES (?, ?, ?)",
                (body.email.strip(), code, int(time.time()) + RESET_CODE_TTL),
            )
        # TODO(stfdv): send the code via SMTP here in production.
        if DISABLE_DEV_CODE:
            return {}
        return {"devCode": code if row else None}


@app.post("/api/v1/auth/reset-password")
def reset_password(body: ResetBody):
    with db() as c:
        row = c.execute(
            "SELECT code, expires_at FROM reset_codes WHERE email = ?", (body.email.strip(),)
        ).fetchone()
        if row is None or row["expires_at"] < time.time() or not hmac.compare_digest(row["code"], body.code.strip()):
            raise HTTPException(400, "Invalid or expired reset code")
        user = c.execute("SELECT id FROM users WHERE email = ?", (body.email.strip(),)).fetchone()
        if user is None:
            raise HTTPException(400, "Invalid or expired reset code")
        c.execute("UPDATE users SET password_hash = ? WHERE id = ?", (hash_password(body.newPassword), user["id"]))
        c.execute("DELETE FROM reset_codes WHERE email = ?", (body.email.strip(),))
        return auth_response(c, user["id"])


@app.post("/api/v1/auth/oauth/google")
def oauth_google():
    raise HTTPException(501, "Google Sign-In is not configured on this server yet")


@app.post("/api/v1/auth/oauth/apple")
def oauth_apple():
    raise HTTPException(501, "Sign in with Apple is not configured on this server yet")


# ---- user endpoints --------------------------------------------------------


@app.get("/api/v1/users/me")
def get_me(user_id: int = Depends(current_user_id)):
    with db() as c:
        return user_json(c.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone())


@app.patch("/api/v1/users/me")
def patch_me(body: PatchMeBody, user_id: int = Depends(current_user_id)):
    columns = {
        "username": body.username, "name": body.name, "gender": body.gender,
        "height_cm": body.heightCm, "weight_kg": body.weightKg, "age": body.age,
        "goal": body.goal, "activity_level": body.activityLevel,
        "units_metric": None if body.unitsMetric is None else int(body.unitsMetric),
        "avatar_seed": body.avatarSeed,
    }
    updates = {k: v for k, v in columns.items() if v is not None}
    with db() as c:
        if updates:
            assignments = ", ".join(f"{k} = ?" for k in updates)
            c.execute(f"UPDATE users SET {assignments} WHERE id = ?", (*updates.values(), user_id))
        return user_json(c.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone())


@app.delete("/api/v1/users/me")
def delete_me(user_id: int = Depends(current_user_id)):
    with db() as c:
        c.execute("DELETE FROM users WHERE id = ?", (user_id,))
    return {}


# ---- weight ----------------------------------------------------------------


@app.get("/api/v1/weight")
def list_weight(user_id: int = Depends(current_user_id)):
    with db() as c:
        rows = c.execute(
            "SELECT date, kg, body_fat_pct FROM weight_entries WHERE user_id = ? ORDER BY date", (user_id,)
        ).fetchall()
    return [{"date": r["date"], "kg": r["kg"], "bodyFatPct": r["body_fat_pct"]} for r in rows]


@app.post("/api/v1/weight")
def add_weight(body: WeightBody, user_id: int = Depends(current_user_id)):
    with db() as c:
        c.execute(
            "INSERT INTO weight_entries (user_id, date, kg, body_fat_pct) VALUES (?, ?, ?, ?)",
            (user_id, time.strftime("%Y-%m-%dT%H:%M:%S"), body.kg, body.bodyFatPct),
        )
        c.execute("UPDATE users SET weight_kg = ? WHERE id = ?", (body.kg, user_id))
    return {}


# ---- measurements ----------------------------------------------------------


@app.get("/api/v1/measurements")
def get_measurements(user_id: int = Depends(current_user_id)):
    with db() as c:
        rows = c.execute("SELECT * FROM measurements WHERE user_id = ?", (user_id,)).fetchall()
    return {
        r["zone"]: {"valueCm": r["value_cm"], "targetCm": r["target_cm"], "history": json.loads(r["history"])}
        for r in rows
    }


@app.put("/api/v1/measurements")
def put_measurements(body: dict, user_id: int = Depends(current_user_id)):
    with db() as c:
        for zone, m in body.items():
            if zone not in MUSCLE_ZONES or not isinstance(m, dict):
                raise HTTPException(422, f"Unknown zone or malformed entry: {zone}")
            c.execute(
                "INSERT OR REPLACE INTO measurements (user_id, zone, value_cm, target_cm, history)"
                " VALUES (?, ?, ?, ?, ?)",
                (user_id, zone, float(m.get("valueCm", 0)), float(m.get("targetCm", 0)),
                 json.dumps(m.get("history", []))),
            )
    return {}


@app.patch("/api/v1/measurements/{zone}")
def patch_zone(zone: str, body: ZonePatchBody, user_id: int = Depends(current_user_id)):
    if zone not in MUSCLE_ZONES:
        raise HTTPException(422, f"Unknown zone: {zone}")
    with db() as c:
        row = c.execute(
            "SELECT value_cm, history FROM measurements WHERE user_id = ? AND zone = ?", (user_id, zone)
        ).fetchone()
        history = json.loads(row["history"]) if row else []
        if row and row["value_cm"]:
            history = [*history, row["value_cm"]]
        c.execute(
            "INSERT OR REPLACE INTO measurements (user_id, zone, value_cm, target_cm, history)"
            " VALUES (?, ?, ?, COALESCE((SELECT target_cm FROM measurements WHERE user_id = ? AND zone = ?), 0), ?)",
            (user_id, zone, body.valueCm, user_id, zone, json.dumps(history)),
        )
    return {}


# ---- support tickets -------------------------------------------------------
# Shapes match the client's SupportTicket/TicketMessage models exactly:
# sender is 'user' | 'admin', status is 'open' | 'closed', ids are strings.


class CreateTicketBody(BaseModel):
    subject: str = Field(min_length=1)
    message: str = Field(min_length=1)


class TicketMessageBody(BaseModel):
    text: str = Field(min_length=1)


def _init_support_tables() -> None:
    with db() as c:
        c.executescript(
            """
            CREATE TABLE IF NOT EXISTS tickets (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                subject TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'open',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS ticket_messages (
                id INTEGER PRIMARY KEY,
                ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
                sender TEXT NOT NULL,
                text TEXT NOT NULL,
                created_at TEXT NOT NULL
            );
            """
        )


_init_support_tables()


def _now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S")


def _ticket_json(c: sqlite3.Connection, ticket: sqlite3.Row) -> dict:
    messages = c.execute(
        "SELECT sender, text, created_at FROM ticket_messages WHERE ticket_id = ? ORDER BY id",
        (ticket["id"],),
    ).fetchall()
    return {
        "id": str(ticket["id"]),
        "subject": ticket["subject"],
        "status": ticket["status"],
        "createdAt": ticket["created_at"],
        "updatedAt": ticket["updated_at"],
        "messages": [
            {"sender": m["sender"], "text": m["text"], "createdAt": m["created_at"]} for m in messages
        ],
    }


def _owned_ticket(c: sqlite3.Connection, ticket_id: str, user_id: int) -> sqlite3.Row:
    row = c.execute(
        "SELECT * FROM tickets WHERE id = ? AND user_id = ?", (ticket_id, user_id)
    ).fetchone()
    if row is None:
        raise HTTPException(404, "Ticket not found")
    return row


@app.get("/api/v1/support/tickets")
def list_tickets(user_id: int = Depends(current_user_id)):
    with db() as c:
        rows = c.execute(
            "SELECT * FROM tickets WHERE user_id = ? ORDER BY updated_at DESC", (user_id,)
        ).fetchall()
        return [_ticket_json(c, r) for r in rows]


@app.get("/api/v1/support/tickets/{ticket_id}")
def get_ticket(ticket_id: str, user_id: int = Depends(current_user_id)):
    with db() as c:
        return _ticket_json(c, _owned_ticket(c, ticket_id, user_id))


@app.post("/api/v1/support/tickets")
def create_ticket(body: CreateTicketBody, user_id: int = Depends(current_user_id)):
    now = _now_iso()
    with db() as c:
        cur = c.execute(
            "INSERT INTO tickets (user_id, subject, status, created_at, updated_at) VALUES (?, ?, 'open', ?, ?)",
            (user_id, body.subject.strip(), now, now),
        )
        c.execute(
            "INSERT INTO ticket_messages (ticket_id, sender, text, created_at) VALUES (?, 'user', ?, ?)",
            (cur.lastrowid, body.message.strip(), now),
        )
        return _ticket_json(c, _owned_ticket(c, str(cur.lastrowid), user_id))


@app.post("/api/v1/support/tickets/{ticket_id}/messages")
def add_ticket_message(ticket_id: str, body: TicketMessageBody, user_id: int = Depends(current_user_id)):
    now = _now_iso()
    with db() as c:
        ticket = _owned_ticket(c, ticket_id, user_id)
        if ticket["status"] == "closed":
            raise HTTPException(409, "This ticket is closed")
        c.execute(
            "INSERT INTO ticket_messages (ticket_id, sender, text, created_at) VALUES (?, 'user', ?, ?)",
            (ticket["id"], body.text.strip(), now),
        )
        c.execute("UPDATE tickets SET updated_at = ? WHERE id = ?", (now, ticket["id"]))
        return _ticket_json(c, _owned_ticket(c, ticket_id, user_id))


# ---- health check ----------------------------------------------------------


@app.get("/api/v1/health")
def health():
    return {"status": "ok"}


# The Flutter client surfaces HTTPException detail strings directly to the
# user via describeApiError — keep them human-readable, not internal jargon.
@app.exception_handler(HTTPException)
def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
