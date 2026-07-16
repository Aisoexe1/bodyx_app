import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.hydrate();
  runApp(BodyXApp(appState: appState));

  // Fire-and-forget: re-arm any reminders the user had enabled last session.
  // Local notifications aren't available on web, and any platform-channel
  // failure here must never delay or break app startup — errors are
  // swallowed inside AppState's sync methods.
  unawaited(appState.syncNotificationSchedules());
}
