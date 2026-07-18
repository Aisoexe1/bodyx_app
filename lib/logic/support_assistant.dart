/// A small local, keyword-matching FAQ assistant for the in-app support
/// chat. This is NOT an AI/LLM call — everything happens on-device with no
/// network request, so [modelName] must never claim to be a real AI model;
/// doing so would be a false capability claim shown directly to users.
class SupportAssistant {
  SupportAssistant._();

  static const String modelName = 'On-device FAQ';

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
      return "Sleep is pulled from Apple Health or Health Connect once "
          "you've enabled sync in Settings. Without a synced wearable, "
          "there's no way to log sleep by hand yet, so it stays at zero.";
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
          'BodyX pulls steps, active calories burned, and sleep from '
          "Apple Health or Health Connect automatically. No wearable? "
          "Everything still works with data you log by hand.";
    }
    if (has(['export', 'download', 'backup', 'data', 'privacy'])) {
      return "There's no export yet — it's on the roadmap. Your profile, "
          "weight and body measurements sync to your account when you're "
          "signed in and a server is reachable; progress photos, meals, "
          "and workouts stay on this device only.";
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
          'Forgot your password? Use "Forgot password" on the sign-in '
          'screen. You can also permanently delete your account and all '
          'its data from Settings → Privacy → Delete account.';
    }
    if (has(['thank', 'thanks', 'спасибо'])) {
      return "You're welcome! Anything else I can help with?";
    }
    return "I don't have a canned answer for that yet — try asking about "
        "water, calories, workouts, weight tracking, sleep, or syncing a "
        "wearable, or check the FAQs above.";
  }
}
