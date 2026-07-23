import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:bodyx_app/logic/support_assistant.dart';

/// [SupportAssistant] now resolves its replies through [AppLocalizations],
/// which needs a real [BuildContext] — pump a minimal localized app and
/// hand tests a context to call it with. Locale pinned to English so the
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
  group('SupportAssistant', () {
    testWidgets(
        'matches keywords case-insensitively regardless of surrounding text',
        (tester) async {
      final context = await _localizedContext(tester);
      final reply =
          SupportAssistant.reply(context, 'How much WATER should I drink?');
      expect(reply, contains('water goal'));
    });

    testWidgets('routes calorie and protein questions to the right answer',
        (tester) async {
      final context = await _localizedContext(tester);
      expect(SupportAssistant.reply(context, 'how are calories tracked'),
          contains('TDEE'));
      expect(SupportAssistant.reply(context, 'what is my protein target'),
          contains('1.8g'));
    });

    testWidgets('routes workout questions to the checklist explanation',
        (tester) async {
      final context = await _localizedContext(tester);
      expect(SupportAssistant.reply(context, 'how do I log a workout set'),
          contains('Plan tab'));
    });

    testWidgets('falls back to a generic pointer for unmatched questions',
        (tester) async {
      final context = await _localizedContext(tester);
      final reply =
          SupportAssistant.reply(context, 'what is the meaning of life');
      expect(reply, contains("don't have a canned answer"));
    });

    testWidgets(
        'modelName does not claim to be a real AI model — this is local '
        'keyword matching, not a live LLM call', (tester) async {
      final context = await _localizedContext(tester);
      final modelName = SupportAssistant.modelName(context);
      expect(modelName, isNotEmpty);
      expect(modelName.toLowerCase(), isNot(contains('claude')));
      expect(modelName.toLowerCase(), isNot(contains('gpt')));
      expect(modelName.toLowerCase(), isNot(contains('gemini')));
    });
  });
}
