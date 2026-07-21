// Verifies the injury tracker's 2D body diagram is actually reachable and
// tappable — unlike the earlier WebView-based 3D version, this is a plain
// CustomPainter + GestureDetector, so real tap coordinates can be driven.
//
// Pumps InjuryBodyScreen directly (the same MaterialApp/localization/
// Provider shell app.dart uses) rather than tapping through the full
// Profile → Body Metrics navigation chain, so the test stays focused on
// the screen itself and isn't coupled to unrelated nav-chain timing.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:bodyx_app/screens/body_metrics/injury_body_screen.dart';
import 'package:bodyx_app/state/app_state.dart';
import 'package:bodyx_app/theme/app_theme.dart';
import 'package:bodyx_app/widgets/body/interactive_injury_body.dart';

import 'fake_repositories.dart';

Widget _harness(AppState appState) => ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InjuryBodyScreen(),
      ),
    );

void main() {
  testWidgets('tapping the head zone opens the sheet and logs an entry',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = newTestAppState();
    await appState.hydrate();
    await appState.signIn('widget-injury@bodyx.app', 'pw', rememberMe: true);

    await tester.pumpWidget(_harness(appState));
    await tester.pumpAndSettle();

    expect(find.text('Injury Tracker'), findsOneWidget);
    expect(appState.injuries, isEmpty);

    // Tap the head zone — its fractional center is (0.5, 0.085), per
    // BodySilhouette.injuryZones().
    final bodyRect = tester.getRect(find.byType(InteractiveInjuryBody));
    await tester.tapAt(Offset(
      bodyRect.left + bodyRect.width * 0.5,
      bodyRect.top + bodyRect.height * 0.085,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Head'), findsOneWidget);

    await tester.tap(find.text('Bruise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    expect(appState.injuries.length, 1);
    expect(appState.injuries.first.bodyPart.name, 'head');

    // The history tile is below the fold — a plain ListView's SliverList
    // only builds children within the viewport + cache extent, so it isn't
    // mounted (and therefore not findable) until scrolled into view.
    await tester.dragUntilVisible(
      find.text('Head · Bruise'),
      find.byType(Scrollable),
      const Offset(0, -150),
    );
    expect(find.text('Head · Bruise'), findsOneWidget);

    appState.dispose();
  });
}
