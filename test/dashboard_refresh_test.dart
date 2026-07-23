// Verifies the Dashboard's pull-to-refresh actually re-hits the server,
// not just that the RefreshIndicator widget is present.
//
// Uses bounded pump()s instead of pumpAndSettle(): the Dashboard hosts the
// pet card's DragonAvatar, which runs a deliberately infinite idle-animation
// AnimationController — pumpAndSettle() never returns while that's in the
// tree, the same reason it's avoided elsewhere (see achievements_screen_test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/app.dart';

import 'fake_repositories.dart';

void main() {
  testWidgets('pulling down on the Dashboard triggers a refresh',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final authRepo = FakeAuthRepository();
    final appState = newTestAppState(authRepository: authRepo);
    await appState.hydrate();
    await appState.signIn('widget-refresh@bodyx.app', 'pw', rememberMe: true);

    await tester.pumpWidget(BodyXApp(appState: appState));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RefreshIndicator), findsOneWidget);
    final callsBeforePull = authRepo.restoreSessionCallCount;

    // Same gesture Flutter's own RefreshIndicator tests use — a fling drags
    // the scroll view down past the activation threshold and releases.
    await tester.fling(
        find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(authRepo.restoreSessionCallCount, greaterThan(callsBeforePull));

    appState.dispose();
  });
}
