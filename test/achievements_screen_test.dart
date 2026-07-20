// Verifies the achievements feature is actually reachable from the UI —
// the rank card on Profile, and the full catalog behind it.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/app.dart';

import 'fake_repositories.dart';

void main() {
  testWidgets('Profile shows the rank card and opens the Achievements screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = newTestAppState();
    await appState.hydrate();
    await appState.signIn('widget-achieve@bodyx.app', 'pw', rememberMe: true);

    await tester.pumpWidget(BodyXApp(appState: appState));
    await tester.pumpAndSettle();

    appState.selectNav(4);
    await tester.pumpAndSettle();

    expect(find.text('Bronze'), findsOneWidget);

    await tester.tap(find.text('Bronze'));
    await tester.pumpAndSettle();

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Getting Started'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);

    appState.dispose();
  });
}
