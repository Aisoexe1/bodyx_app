import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:bodyx_app/screens/dashboard/log_meal_sheet.dart';
import 'package:bodyx_app/state/app_state.dart';
import 'package:bodyx_app/theme/app_theme.dart';
import 'package:bodyx_app/widgets/common/scale_tap.dart';

import 'fake_repositories.dart';

// Taps a chip/row by calling its ScaleTap.onTap directly rather than
// tester.tap — nested sheet/route hit-testing can produce misleading
// "would not hit test" warnings unrelated to whether the tap logic itself
// works (see body_metrics/injury tests for the same pattern).
Future<void> _tapScaleTapAncestorOf(WidgetTester tester, String label) async {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(ScaleTap),
  );
  tester.widget<ScaleTap>(finder.first).onTap?.call();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every category chip scrolls the list to its section',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = newTestAppState();
    await appState.hydrate();
    await appState.signIn('categoryjump@bodyx.app', 'pw', rememberMe: true);

    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const LogMealSheet(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Near-top category: chip is already on-screen in the chip row, and
    // its section is already on-screen in the results list — fast path.
    await _tapScaleTapAncestorOf(tester, 'Cheese');
    expect(find.text('Cheese').evaluate().length, 2);

    // A middle category: chip is on-screen, but its section further down
    // the results list is not yet built — exercises the estimate+retry
    // scroll fallback in _jumpToCategory.
    await _tapScaleTapAncestorOf(tester, 'Dairy');
    expect(find.text('Dairy').evaluate().length, 2);

    // The last category: its chip is itself scrolled off the right edge
    // of the chip row, same as it would be on a real device — swipe the
    // chip row to reveal it before tapping, exactly as a user would.
    await tester.drag(find.byType(ListView), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    await _tapScaleTapAncestorOf(tester, 'Other');
    expect(find.text('Other').evaluate().length, 2);

    appState.dispose();
  });
}
