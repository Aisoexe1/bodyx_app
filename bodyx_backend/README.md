# BodyX Backend

FastAPI + MongoDB backend for the BodyX Flutter app, covering auth, user profile,
weight-entry history, and body-measurement history. See `../bodyx_app` for the client.

## Run locally (no Docker)

```bash
python -m venv venv
venv\Scripts\pip install -r requirements.txt   # Windows
# source venv/bin/activate && pip install -r requirements.txt   # macOS/Linux

copy .env.example .env   # then fill in MONGO_URI (Atlas connection string or local mongod)
venv\Scripts\python -m uvicorn app.main:app --reload
```

API docs: http://localhost:8000/docs
Admin panel: http://localhost:8000/admin (see "Admin panel" below)

## Run with Docker Compose

```bash
copy .env.example .env   # fill in MONGO_URI
docker compose up --build
```

By default `docker-compose.yml` expects `MONGO_URI` in `.env` to point at a reachable
Mongo instance (e.g. Atlas). To run MongoDB in a container too, uncomment the `mongo`
service in `docker-compose.yml` and set `MONGO_URI=mongodb://mongo:27017` in `.env`.

## Admin panel

Bootstrap the first superadmin (one-time, chicken-and-egg — role management requires
an existing superadmin):

```bash
venv\Scripts\python -m scripts.create_superadmin
```

Then log in at http://localhost:8000/admin with those credentials.

## Tests

```bash
venv\Scripts\python -m pytest -v
```

Tests run against an in-memory `mongomock` database (see `tests/conftest.py`) — they
never touch the real MongoDB instance configured in `.env`.

## curl smoke test

```bash
# Register
curl -X POST localhost:8000/api/v1/auth/register -H "Content-Type: application/json" \
  -d '{"email":"a@b.com","username":"alex","password":"secret123"}'

# Copy accessToken from the response, then:
TOKEN=<paste token here>

curl localhost:8000/api/v1/users/me -H "Authorization: Bearer $TOKEN"

curl -X POST localhost:8000/api/v1/weight -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"kg":80.5,"bodyFatPct":15.2}'

curl localhost:8000/api/v1/weight -H "Authorization: Bearer $TOKEN"

curl localhost:8000/api/v1/measurements -H "Authorization: Bearer $TOKEN"
```

## Notes

- `MONGO_URI` supports both `mongodb://` (local) and `mongodb+srv://` (Atlas) schemes.
- No refresh tokens in this MVP — access tokens are long-lived (30 days by default,
  `ACCESS_TOKEN_EXPIRE_MINUTES` in `.env`). Revisit before any real release.
- `DailyStats`, `MealEntry`, `PlanTask`, and `AlertItem` are intentionally not covered
  by this backend yet — see the project plan for the deferred-work rationale.
