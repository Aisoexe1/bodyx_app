# BodyX

A premium, dark-neon Health & Fitness tracker prototype built with Flutter. Features an
interactive pseudo-3D body-metrics visualizer, sleep/calorie/step tracking with charts,
and a full auth → onboarding → main-app flow — all backed by deterministic mock data.

## Stack

- **State management:** `provider` (a single `AppState` `ChangeNotifier`)
- **Charts:** `fl_chart` (bar / line / donut) + custom `CustomPainter` sparklines
- **Body visualization:** hand-rolled `CustomPainter` (`lib/widgets/body/`) — a fractional,
  gender-aware humanoid silhouette with tappable muscle-zone hotspots, pulse animation on
  the selected zone, and a front/back view toggle. No 3D model assets required.
- **Fonts:** `google_fonts` (Inter)

## Project layout

```
lib/
  app.dart              # MaterialApp + auth-stage router (splash/auth/onboarding/main)
  main.dart
  theme/                 # colors, spacing, ThemeData
  models/                # plain data classes (UserProfile, DailyStats, BodyMeasurement, ...)
  data/mock_data.dart     # deterministic mock-data generators
  state/app_state.dart    # single ChangeNotifier holding all app state
  widgets/
    common/               # GlowCard, buttons, inputs, ProgressRing, ScaleTap
    charts/               # sleep donut, steps bar chart, weight line chart, sparkline, macros
    body/                 # body_geometry.dart, body_painter.dart, interactive_body.dart
    nav/bottom_nav.dart
  screens/
    splash_screen.dart
    auth/                 # sign in, sign up, choose username, body data onboarding
    dashboard/            # Home tab
    progress/             # Progress tab
    plan/                 # Plan tab + Daily Plan + Daily Summary (sleep breakdown)
    body_metrics/         # Body Metrics screen, camera-scan mock, log-metrics sheet
    alerts/                # Alerts tab
    profile/, settings/    # Profile tab + all settings sub-screens
```

## Running it

```bash
flutter pub get
flutter run            # pick a connected device/simulator, or:
flutter run -d chrome  # web
flutter run -d macos   # macOS desktop (requires flutter config --enable-macos-desktop)
```

To produce an optimized web build (recommended over `flutter run -d web-server` for actually
using/demoing the app — the debug DDC bundle is much heavier):

```bash
flutter build web --release
cd build/web && python3 -m http.server 8765
```

## Notes

- All data is mocked (`lib/data/mock_data.dart`) with a fixed random seed, so numbers are
  stable across rebuilds within a session but reset on a fresh app launch — there's no
  backend or persistence layer.
- `flutter analyze` and `flutter test` both pass clean.
