import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/logic/date_format_helpers.dart';

void main() {
  group('formatElapsed', () {
    test('the exact same day reads distinctly from one day apart', () {
      final a = DateTime(2026, 1, 1);
      expect(formatElapsed(a, a), 'Same day');
      expect(formatElapsed(a, DateTime(2026, 1, 2)), '1 day apart');
    });

    test('short gaps read as a day count', () {
      final a = DateTime(2026, 1, 1);
      expect(formatElapsed(a, DateTime(2026, 1, 15)), '14 days apart');
      expect(formatElapsed(a, DateTime(2026, 2, 20)), '50 days apart');
    });

    test('medium gaps read as a month count', () {
      final a = DateTime(2026, 1, 1);
      expect(formatElapsed(a, DateTime(2026, 3, 5)), '2 months apart');
      expect(formatElapsed(a, DateTime(2026, 8, 1)), '7 months apart');
    });

    test('gaps over a year read as years plus leftover months', () {
      final a = DateTime(2024, 1, 1);
      expect(formatElapsed(a, DateTime(2025, 1, 1)), '1 year apart');
      expect(formatElapsed(a, DateTime(2025, 4, 15)), '1 year 3 months apart');
      expect(formatElapsed(a, DateTime(2026, 1, 1)), '2 years apart');
    });

    test('a leftover-month count that rounds up to 12 rolls into a year',
        () {
      final a = DateTime(2024, 1, 1);
      // 710-729 days is close enough to 2 full years that the leftover
      // month count (days % 365 / 30, rounded) hits 12 — that must roll
      // into the year count instead of ever printing "12 months".
      for (final days in [700, 710, 715, 720, 725, 729, 730]) {
        final result = formatElapsed(a, a.add(Duration(days: days)));
        expect(result, isNot(contains('12 months')),
            reason: 'at $days days: $result');
      }
      expect(formatElapsed(a, a.add(const Duration(days: 720))),
          '2 years apart');
    });

    test('is order-independent (absolute difference)', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 15);
      expect(formatElapsed(a, b), formatElapsed(b, a));
    });
  });
}
