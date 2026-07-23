# BodyX

A premium, dark-neon Health & Fitness tracker built with Flutter (iOS-first). Tracks
workouts, mobility/stretching, meals, water, weight, body measurements, and progress
photos, with an interactive pseudo-3D body-metrics visualizer, real HealthKit /
Health Connect sync, Lock Screen / Dynamic Island live timers, and a Home Screen widget.
Localized in English, Russian, and Ukrainian.

## Stack

- **State management:** `provider` (a single `AppState` `ChangeNotifier`)
- **Persistence:** `shared_preferences` (local source of truth; day-scoped for "today"
  data) + `flutter_secure_storage` (JWT in Keychain) + on-disk photo storage
- **Backend:** REST client in `lib/network/` (repository pattern, JWT auth) — the app
  works fully offline; server sync is best-effort. No production backend is deployed
  yet; the base URL is a build-time `--dart-define=API_BASE_URL`.
- **Health:** `health` package — read-only HealthKit / Health Connect (steps, calories,
  sleep stages, water, weight, body fat)
- **iOS native:** WidgetKit Home Screen widget + ActivityKit Live Activities
  (`ios/BodyXWidgets/`), shared via App Group `group.com.bodyx.bodyxApp`
- **Charts:** `fl_chart` + custom `CustomPainter` sparklines
- **Body visualization:** hand-rolled `CustomPainter` (`lib/widgets/body/`) — tappable
  muscle-zone hotspots, front/back toggle, no 3D assets
- **Privacy:** no analytics, advertising, or crash-reporting SDKs (see `PRIVACY_POLICY.md`)

## Project layout

```
lib/
  app.dart               # MaterialApp + auth-stage router (splash/auth/onboarding/main)
  main.dart
  theme/                 # colors, spacing, ThemeData
  models/                # plain data classes (UserProfile, DailyStats, ...)
  data/                  # food database (117 items, en/ru/uk), empty-state seeds
  l10n/                  # ARB files (en/ru/uk) + generated AppLocalizations
  logic/                 # pure logic: health insights, label localization helpers
  network/               # ApiClient, repositories, TokenStorage, OAuth config
  state/                 # AppState, PersistenceService, Health/Notification/
                         #   LiveActivity/WidgetOverview services, photo storage
  widgets/               # common/, charts/, body/, nav/
  screens/               # splash, auth/, dashboard/, progress/, plan/,
                         #   body_metrics/, alerts/, profile/, settings/
ios/
  Runner/                # AppDelegate (classic lifecycle), LiveActivityBridge
  BodyXWidgets/          # Home Screen widget + Live Activities extension
```

## Running it

```bash
flutter pub get
flutter analyze && flutter test
flutter build ios --release                       # signed device build
flutter install --release -d <device-id>          # install to iPhone (needs prior build)
```

Knowledge base (architecture, decisions, bugs, TODO) lives in the team's Obsidian vault.
