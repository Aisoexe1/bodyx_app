import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/logic/support_assistant.dart';

void main() {
  group('SupportAssistant', () {
    test('matches keywords case-insensitively regardless of surrounding text',
        () {
      final reply = SupportAssistant.reply('How much WATER should I drink?');
      expect(reply, contains('water goal'));
    });

    test('routes calorie and protein questions to the right answer', () {
      expect(SupportAssistant.reply('how are calories tracked'),
          contains('TDEE'));
      expect(SupportAssistant.reply('what is my protein target'),
          contains('1.8g'));
    });

    test('routes workout questions to the checklist explanation', () {
      expect(SupportAssistant.reply('how do I log a workout set'),
          contains('Plan tab'));
    });

    test('falls back to a generic pointer for unmatched questions', () {
      final reply = SupportAssistant.reply('what is the meaning of life');
      expect(reply, contains("don't have a canned answer"));
    });

    test('modelName does not claim to be a real AI model — this is local '
        'keyword matching, not a live LLM call', () {
      expect(SupportAssistant.modelName, isNotEmpty);
      expect(SupportAssistant.modelName.toLowerCase(), isNot(contains('claude')));
      expect(SupportAssistant.modelName.toLowerCase(), isNot(contains('gpt')));
      expect(SupportAssistant.modelName.toLowerCase(), isNot(contains('gemini')));
    });
  });
}
