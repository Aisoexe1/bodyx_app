# BodyX backend

FastAPI + SQLite. Implements exactly the contract the Flutter client already speaks
(`lib/network/`): auth (register/login/forgot/reset, JWT), `/users/me` CRUD,
`/weight`, `/measurements`. OAuth endpoints return 501 until Google/Apple client
IDs are configured.

## Run locally
```bash
pip3 install -r requirements.txt
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
# interactive docs: http://localhost:8000/api/v1/docs
```

Point the app at it (device on the same Wi-Fi, use the Mac's LAN IP):
```bash
flutter run --dart-define=API_BASE_URL=http://<mac-ip>:8000/api/v1
```

## Deploy (free tier: Render / Railway / Fly)
The Dockerfile is all you need. Set env vars:
- `JWT_SECRET` — required in production (otherwise tokens die on restart)
- `BODYX_DB` — path on a persistent volume, e.g. `/data/bodyx.db`
- `DISABLE_DEV_CODE=1` — once SMTP is wired up (until then, password-reset codes
  are echoed in the API response for dev use; see `forgot_password` in main.py)

Then set the app's release build to the deployed URL:
```bash
flutter build ios --release --dart-define=API_BASE_URL=https://<your-host>/api/v1
```
