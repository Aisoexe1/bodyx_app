import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';

/// A small local, keyword-matching FAQ assistant for the in-app support
/// chat. This is NOT an AI/LLM call — everything happens on-device with no
/// network request, so [modelName] must never claim to be a real AI model;
/// doing so would be a false capability claim shown directly to users.
class SupportAssistant {
  SupportAssistant._();

  static String modelName(BuildContext context) =>
      AppLocalizations.of(context)!.supportAssistantModelName;

  static String reply(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    final q = message.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);

    if (has(['hi', 'hello', 'hey', 'привет', 'yo'])) {
      return l10n.supportAssistantReplyGreeting;
    }
    if (has(['water', 'hydration', 'drink', 'thirst'])) {
      return l10n.supportAssistantReplyWater;
    }
    if (has(
        ['calorie', 'kcal', 'food', 'meal', 'eat', 'diet', 'nutrition'])) {
      return l10n.supportAssistantReplyCalories;
    }
    if (has(['protein'])) {
      return l10n.supportAssistantReplyProtein;
    }
    if (has([
      'workout',
      'exercise',
      'set',
      'rep',
      'gym',
      'training',
      'strength'
    ])) {
      return l10n.supportAssistantReplyWorkout;
    }
    if (has(['weight', 'scan', 'bmi', 'body fat', 'composition', 'bodyfat'])) {
      return l10n.supportAssistantReplyWeight;
    }
    if (has(['sleep'])) {
      return l10n.supportAssistantReplySleep;
    }
    if (has([
      'sync',
      'wearable',
      'watch',
      'apple health',
      'health connect',
      'device'
    ])) {
      return l10n.supportAssistantReplySync;
    }
    if (has(['export', 'download', 'backup', 'data', 'privacy'])) {
      return l10n.supportAssistantReplyExport;
    }
    if (has(['goal', 'target'])) {
      return l10n.supportAssistantReplyGoal;
    }
    if (has(['notification', 'reminder', 'alert'])) {
      return l10n.supportAssistantReplyNotifications;
    }
    if (has([
      'password',
      'account',
      'sign out',
      'log out',
      'delete account',
      'login'
    ])) {
      return l10n.supportAssistantReplyAccount;
    }
    if (has(['thank', 'thanks', 'спасибо'])) {
      return l10n.supportAssistantReplyThanks;
    }
    return l10n.supportAssistantReplyFallback;
  }
}
