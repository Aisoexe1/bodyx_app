/// A small local, keyword-matching FAQ assistant for the in-app support
/// chat. This is NOT a live LLM call — the prototype has no backend or API
/// key to call one safely, and pretending otherwise would be dishonest. In
/// production this is designed to be swapped for a real model without
/// changing the chat UI at all, and [modelName] names the one that fits:
/// Claude Haiku 4.5 is fast and inexpensive enough for high-volume,
/// low-latency support triage like this, reserving escalation to a larger
/// model for anything the keyword rules below can't resolve.
class SupportAssistant {
  SupportAssistant._();

  static const String modelName = 'Claude Haiku 4.5';

  static String reply(String message) {
    final q = message.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);

    if (has(['hi', 'hello', 'hey', 'привет', 'yo'])) {
      return "Hey! I'm the BodyX assistant. Ask me about water, calories, "
          "workouts, weight tracking, sleep, or syncing a wearable.";
    }
    if (has(['water', 'hydration', 'drink', 'thirst'])) {
      return 'Your water goal scales with your body weight and rises on '
          "workout days. Tap the Water card on the dashboard any time you "
          "drink to log it — the ring fills up and the status dot tells "
          "you if you're on pace for the day.";
    }
    if (has(
        ['calorie', 'kcal', 'food', 'meal', 'eat', 'diet', 'nutrition'])) {
      return 'Calories eaten come from meals you log yourself — tap the '
          'Calories card to search the food database or add a custom '
          'entry. Your target (TDEE) is calculated from your age, weight, '
          'height, gender and activity level with the Mifflin-St Jeor '
          'formula.';
    }
    if (has(['protein'])) {
      return "Your protein target is 1.8g per kg of body weight — a solid "
          "range for building or maintaining muscle. It's tracked against "
          "the meals you log, and updates automatically if your weight "
          "changes.";
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
      return "Today's workout lives on the Plan tab — tap the workout "
          "card to open the set-by-set checklist and tick off each set as "
          "you finish it. Your progress saves automatically, even if you "
          "close the app mid-workout.";
    }
    if (has(['weight', 'scan', 'bmi', 'body fat', 'composition', 'bodyfat'])) {
      return 'Log your weight and body-fat % from "Log body weight" on the '
          'dashboard checklist. We combine the weight trend with the '
          'body-fat trend so we can tell muscle gain from fat gain, '
          "instead of just watching the scale number.";
    }
    if (has(['sleep'])) {
      return "Sleep is pulled from Apple Health or Health Connect if "
          "you've enabled sync in Settings. Without a synced wearable, "
          "recent days show sample data so the dashboard stays populated "
          "for the demo.";
    }
    if (has([
      'sync',
      'wearable',
      'watch',
      'apple health',
      'health connect',
      'device'
    ])) {
      return 'Go to Settings → toggle "Sync with Health". Once enabled, '
          'BodyX pulls steps, active calories burned, sleep and heart '
          "rate from Apple Health or Health Connect automatically. No "
          "wearable? Everything still works with data you log by hand.";
    }
    if (has(['export', 'download', 'backup', 'data', 'privacy'])) {
      return "There's no export yet — it's on the roadmap. Everything you "
          "log (weight, meals, workouts) is stored locally on this device "
          "only; nothing is uploaded to a server.";
    }
    if (has(['goal', 'target'])) {
      return 'Step and calorie goals are derived from your profile in '
          'Profile → Edit profile. Update your weight, height, age or '
          'activity level and your targets recalculate automatically — '
          "there's no manual override yet.";
    }
    if (has(['notification', 'reminder', 'alert'])) {
      return 'Workout and hydration reminders can be switched on in '
          'Settings → Notifications. You control exactly which ones fire '
          'and when.';
    }
    if (has([
      'password',
      'account',
      'sign out',
      'log out',
      'delete account',
      'login'
    ])) {
      return 'Account and sign-out controls live in Profile → Settings. '
          "This prototype stores everything on-device, so there's no "
          'password-reset flow to worry about.';
    }
    if (has(['thank', 'thanks', 'спасибо'])) {
      return "You're welcome! Anything else I can help with?";
    }
    return "I don't have a canned answer for that yet — try asking about "
        "water, calories, workouts, weight tracking, sleep, or syncing a "
        "wearable, or check the FAQs above.";
  }
}
