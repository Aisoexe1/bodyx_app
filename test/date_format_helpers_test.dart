import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:bodyx_app/logic/date_format_helpers.dart';

/// [formatElapsed] now resolves its text through [AppLocalizations], which
/// needs a real [BuildContext] — pump a minimal localized app and hand
/// tests a context to call it with. Locale pinned to English so the
/// content assertions below are stable regardless of the test runner's
/// default locale.
Future<BuildContext> _localizedContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  group('formatElapsed', () {
    testWidgets('the exact same day reads distinctly from one day apart',
        (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2026, 1, 1);
      expect(formatElapsed(context, a, a), 'Same day');
      expect(formatElapsed(context, a, DateTime(2026, 1, 2)), '1 day apart');
    });

    testWidgets('short gaps read as a day count', (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2026, 1, 1);
      expect(
          formatElapsed(context, a, DateTime(2026, 1, 15)), '14 days apart');
      expect(
          formatElapsed(context, a, DateTime(2026, 2, 20)), '50 days apart');
    });

    testWidgets('medium gaps read as a month count', (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2026, 1, 1);
      expect(
          formatElapsed(context, a, DateTime(2026, 3, 5)), '2 months apart');
      expect(
          formatElapsed(context, a, DateTime(2026, 8, 1)), '7 months apart');
    });

    testWidgets('gaps over a year read as years plus leftover months',
        (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2024, 1, 1);
      expect(formatElapsed(context, a, DateTime(2025, 1, 1)), '1 year apart');
      expect(formatElapsed(context, a, DateTime(2025, 4, 15)),
          '1 year 3 months apart');
      expect(formatElapsed(context, a, DateTime(2026, 1, 1)), '2 years apart');
    });

    testWidgets(
        'a leftover-month count that rounds up to 12 rolls into a year',
        (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2024, 1, 1);
      // 710-729 days is close enough to 2 full years that the leftover
      // month count (days % 365 / 30, rounded) hits 12 — that must roll
      // into the year count instead of ever printing "12 months".
      for (final days in [700, 710, 715, 720, 725, 729, 730]) {
        final result = formatElapsed(context, a, a.add(Duration(days: days)));
        expect(result, isNot(contains('12 months')),
            reason: 'at $days days: $result');
      }
      expect(formatElapsed(context, a, a.add(const Duration(days: 720))),
          '2 years apart');
    });

    testWidgets('is order-independent (absolute difference)', (tester) async {
      final context = await _localizedContext(tester);
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 15);
      expect(formatElapsed(context, a, b), formatElapsed(context, b, a));
    });
  });
}
