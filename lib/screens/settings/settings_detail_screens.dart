import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/goal_labels.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import 'contact_support_screen.dart';

/// Shared chrome for every settings sub-screen: back button + title,
/// scrollable body.
class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name =
      TextEditingController(text: context.read<AppState>().user?.name ?? '');
  late final _username = TextEditingController(
      text: context.read<AppState>().user?.username ?? '');

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsEditProfileTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryTextField(
              label: AppLocalizations.of(context)!.settingsFullNameLabel,
              controller: _name),
          const SizedBox(height: 14),
          PrimaryTextField(
              label: AppLocalizations.of(context)!.settingsUsernameLabel,
              controller: _username,
              prefixIcon: Icons.alternate_email_rounded),
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppLocalizations.of(context)!.settingsSaveChangesButton,
            onPressed: () {
              context.read<AppState>().updateProfile(
                  name: _name.text, username: _username.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// "Personal data" — bundles Height / Weight / Age / Gender into a single
/// entry point instead of exposing each as its own top-level Profile row.
class PersonalDataScreen extends StatelessWidget {
  const PersonalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final rows = <(IconData, String, String, WidgetBuilder)>[
      (
        Icons.straighten_rounded,
        AppLocalizations.of(context)!.settingsHeightLabel,
        AppLocalizations.of(context)!
            .settingsHeightValueCm(user?.heightCm.toStringAsFixed(0) ?? '--'),
        (ctx) => const EditHeightScreen()
      ),
      (
        Icons.monitor_weight_outlined,
        AppLocalizations.of(context)!.settingsWeightLabel,
        AppLocalizations.of(context)!
            .settingsWeightValueKg(user?.weightKg.toStringAsFixed(0) ?? '--'),
        (ctx) => const EditWeightScreen()
      ),
      (
        Icons.cake_outlined,
        AppLocalizations.of(context)!.settingsAgeLabel,
        '${user?.age ?? '--'}',
        (ctx) => const EditAgeScreen()
      ),
      (
        Icons.wc_rounded,
        AppLocalizations.of(context)!.settingsGenderLabel,
        user?.gender.name ?? 'male',
        (ctx) => const EditGenderScreen()
      ),
    ];

    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsPersonalDataTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.settingsPersonalDataDescription,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          GlowCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(rows.length, (i) {
                final (icon, label, value, builder) = rows[i];
                return Column(
                  children: [
                    ScaleTap(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: builder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 14),
                        child: Row(
                          children: [
                            Icon(icon, color: AppColors.primaryBright, size: 20),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(label,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            Text(value,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                    if (i != rows.length - 1)
                      const Divider(
                          height: 1,
                          color: AppColors.divider,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberEditScreen extends StatefulWidget {
  const _NumberEditScreen({
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.initial,
    required this.onSave,
  });

  final String title;
  final String unit;
  final double min;
  final double max;
  final double step;
  final double initial;
  final ValueChanged<double> onSave;

  @override
  State<_NumberEditScreen> createState() => _NumberEditScreenState();
}

class _NumberEditScreenState extends State<_NumberEditScreen> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: widget.title,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('${_value.toStringAsFixed(widget.step < 1 ? 1 : 0)} ${widget.unit}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 44)),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.primaryBright,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              onChanged: (v) => setState(() => _value = v),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppLocalizations.of(context)!.settingsSaveButton,
            onPressed: () {
              widget.onSave(_value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class EditHeightScreen extends StatelessWidget {
  const EditHeightScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return _NumberEditScreen(
      title: AppLocalizations.of(context)!.settingsEditHeightTitle,
      unit: AppLocalizations.of(context)!.settingsCmUnit,
      min: 130,
      max: 220,
      step: 1,
      initial: state.user?.heightCm ?? 175,
      onSave: (v) => state.updateHeightWeightAge(heightCm: v),
    );
  }
}

class EditWeightScreen extends StatelessWidget {
  const EditWeightScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return _NumberEditScreen(
      title: AppLocalizations.of(context)!.settingsEditWeightTitle,
      unit: AppLocalizations.of(context)!.settingsKgUnit,
      min: 35,
      max: 180,
      step: 0.5,
      initial: state.user?.weightKg ?? 70,
      onSave: (v) => state.updateHeightWeightAge(weightKg: v),
    );
  }
}

class EditAgeScreen extends StatelessWidget {
  const EditAgeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return _NumberEditScreen(
      title: AppLocalizations.of(context)!.settingsEditAgeTitle,
      unit: AppLocalizations.of(context)!.settingsYrsUnit,
      min: 13,
      max: 90,
      step: 1,
      initial: (state.user?.age ?? 25).toDouble(),
      onSave: (v) => state.updateHeightWeightAge(age: v.round()),
    );
  }
}

class EditGenderScreen extends StatefulWidget {
  const EditGenderScreen({super.key});
  @override
  State<EditGenderScreen> createState() => _EditGenderScreenState();
}

class _EditGenderScreenState extends State<EditGenderScreen> {
  late Gender _gender = context.read<AppState>().user?.gender ?? Gender.male;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsEditGenderTitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _choiceCard(
                    AppLocalizations.of(context)!.settingsMaleLabel,
                    Icons.male_rounded,
                    Gender.male,
                    AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _choiceCard(
                    AppLocalizations.of(context)!.settingsFemaleLabel,
                    Icons.female_rounded,
                    Gender.female,
                    AppColors.pink),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppLocalizations.of(context)!.settingsSaveButton,
            onPressed: () {
              context.read<AppState>().updateGender(_gender);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _choiceCard(String label, IconData icon, Gender g, Color accent) {
    final selected = g == _gender;
    return ScaleTap(
      onTap: () => setState(() => _gender = g),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: selected ? accent : AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 30,
                color: selected ? accent : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});
  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const _goals = [
    ('Lose weight', Icons.trending_down_rounded),
    ('Build muscle', Icons.fitness_center_rounded),
    ('Maintain weight', Icons.balance_rounded),
    ('Improve endurance', Icons.directions_run_rounded),
  ];
  late String _selected = context.read<AppState>().user?.goal ?? 'Build muscle';

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsYourGoalTitle,
      child: Column(
        children: [
          ..._goals.map((g) {
            final selected = g.$1 == _selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ScaleTap(
                onTap: () => setState(() => _selected = g.$1),
                child: GlowCard(
                  borderColor: selected ? AppColors.primary : null,
                  child: Row(
                    children: [
                      GlowIconBadge(
                          icon: g.$2,
                          color: selected
                              ? AppColors.primaryBright
                              : AppColors.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(goalLabel(context, g.$1),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600))),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryBright),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          PrimaryButton(
            label: AppLocalizations.of(context)!.settingsSaveGoalButton,
            onPressed: () {
              context.read<AppState>().updateProfile(goal: _selected);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _handleNotifications(bool value) async {
    final granted = await context.read<AppState>().toggleNotifications(value);
    if (!mounted) return;
    if (value && !granted) _showDeniedSnackBar();
  }

  Future<void> _handleWorkoutReminders(bool value) async {
    final granted =
        await context.read<AppState>().toggleWorkoutReminders(value);
    if (!mounted) return;
    if (value && !granted) _showDeniedSnackBar();
  }

  void _showDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.settingsNotificationsAccessDenied)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsNotificationsTitle,
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.notifications_active_outlined,
            label: AppLocalizations.of(context)!.settingsPushNotificationsLabel,
            value: state.notificationsEnabled,
            onChanged: _handleNotifications,
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.fitness_center_rounded,
            label: AppLocalizations.of(context)!.settingsWorkoutRemindersLabel,
            value: state.workoutRemindersEnabled,
            onChanged: _handleWorkoutReminders,
          ),
        ],
      ),
    );
  }
}

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});
  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  bool _syncing = false;

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return AppLocalizations.of(context)!.settingsAppleHealthLabel;
      case TargetPlatform.android:
        return AppLocalizations.of(context)!.settingsHealthConnectLabel;
      default:
        return AppLocalizations.of(context)!.settingsHealthAppLabel;
    }
  }

  Future<void> _handleToggle(bool value) async {
    final granted = await context.read<AppState>().toggleHealthSync(value);
    if (!mounted) return;
    if (value && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .settingsHealthAccessDenied(_platformLabel))),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    HapticFeedback.mediumImpact();
    await context.read<AppState>().syncHealthData();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .settingsSyncedWithPlatform(_platformLabel))));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsHealthSyncTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleRow(
            icon: Icons.favorite_border_rounded,
            label: AppLocalizations.of(context)!
                .settingsSyncWithPlatformLabel(_platformLabel),
            value: state.healthSyncEnabled,
            onChanged: (v) => _handleToggle(v),
          ),
          const SizedBox(height: 14),
          const Text(
            'Reads steps, calories, sleep, water, weight and body fat '
            'percentage to keep your dashboard accurate. BodyX never '
            'writes data back.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (state.healthSyncEnabled) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: AppLocalizations.of(context)!.settingsSyncNowButton,
              loading: _syncing,
              onPressed: _syncing ? null : _syncNow,
            ),
          ],
        ],
      ),
    );
  }
}

class UnitsLanguageScreen extends StatelessWidget {
  const UnitsLanguageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsUnitsLanguageTitle,
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.straighten_rounded,
            label: AppLocalizations.of(context)!.settingsUseMetricUnitsLabel,
            value: state.user?.unitsMetric ?? true,
            onChanged: (_) => context.read<AppState>().toggleUnits(),
          ),
          const SizedBox(height: 10),
          _LanguageRow(locale: state.locale),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.locale});
  final Locale? locale;

  static const _options = <String, String>{
    'en': 'English (US)',
    'ru': 'Русский',
    'uk': 'Українська',
  };

  @override
  Widget build(BuildContext context) {
    final label = _options[locale?.languageCode] ?? _options['en']!;
    return ScaleTap(
      onTap: () => _showPicker(context),
      child: GlowCard(
        child: Row(
          children: [
            const Icon(Icons.language_rounded, color: AppColors.primaryBright),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppLocalizations.of(context)!.settingsLanguageLabel,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final appState = context.read<AppState>();
    final currentCode = locale?.languageCode ?? 'en';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options.entries.map((entry) {
            final selected = currentCode == entry.key;
            return ListTile(
              title: Text(entry.value,
                  style: const TextStyle(color: AppColors.textPrimary)),
              trailing: selected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primaryBright)
                  : null,
              onTap: () {
                appState.setLocale(entry.key == 'en' ? null : Locale(entry.key));
                Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
            AppLocalizations.of(context)!.settingsDeleteAccountDialogTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
            AppLocalizations.of(context)!.settingsDeleteAccountDialogContent,
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text(AppLocalizations.of(context)!.settingsCancelButton)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                  AppLocalizations.of(context)!
                      .settingsDeleteAccountConfirmButton,
                  style: const TextStyle(
                      color: AppColors.warningDeep,
                      fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    HapticFeedback.mediumImpact();
    await context.read<AppState>().deleteAccount();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsPrivacyTitle,
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.public_rounded,
            label: AppLocalizations.of(context)!.settingsPublicProfileLabel,
            value: state.publicProfile,
            onChanged: (v) => context.read<AppState>().togglePublicProfile(v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.analytics_outlined,
            label: AppLocalizations.of(context)!.settingsShareAnonDataLabel,
            value: state.shareAnonData,
            onChanged: (v) => context.read<AppState>().toggleShareAnonData(v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: AppLocalizations.of(context)!.settingsDeleteAccountLabel,
              outlined: true,
              loading: _deleting,
              onPressed: _deleting ? null : _confirmDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'How is my body scan calculated?',
      a: 'Log your weight and body-fat % from "Log body weight" on the '
          'dashboard checklist. We combine the weight trend with the '
          "body-fat trend so we can tell muscle gain from fat gain, "
          "instead of just watching the scale number move.",
    ),
    (
      q: 'How do I sync a wearable device?',
      a: 'Go to Settings → toggle "Sync with Health". Once enabled, BodyX '
          'pulls steps, active calories burned and sleep from Apple '
          'Health or Health Connect automatically. No wearable? '
          'Everything still works with data you log by hand.',
    ),
    (
      q: 'Where do my calorie and protein targets come from?',
      a: 'Your calorie target (TDEE) is calculated from your age, weight, '
          'height, gender and activity level using the Mifflin-St Jeor '
          'formula. Protein target is 1.8g per kg of body weight. Both '
          'update automatically if you edit your profile.',
    ),
    (
      q: 'How do I track a workout?',
      a: "Open the Plan tab and tap the workout card — it opens a "
          "set-by-set checklist. Tap each set as you finish it; progress "
          "saves automatically, even if you close the app mid-workout.",
    ),
    (
      q: 'Can I export my progress data?',
      a: "Not yet — that's on the roadmap. Your profile, weight and body "
          "measurements sync to your account when you're signed in and a "
          "server is reachable; progress photos, meals, and workouts stay "
          "on this device only.",
    ),
    (
      q: 'How do I change my daily goals?',
      a: 'Step and calorie goals are derived from your profile in Profile '
          '→ Edit profile. Update your weight, height, age or activity '
          "level and your targets recalculate automatically — there's no "
          'manual override yet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsHelpSupportTitle,
      child: Column(
        children: [
          ScaleTap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
            ),
            child: GlowCard(
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primaryBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            AppLocalizations.of(context)!
                                .settingsContactSupportLabel,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            AppLocalizations.of(context)!
                                .settingsContactSupportSubtitle,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                AppLocalizations.of(context)!.settingsFrequentlyAskedHeader,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          ..._faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FaqTile(question: faq.q, answer: faq.a),
              )),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5))),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded,
                      color: AppColors.textMuted),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(widget.answer,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.5)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: AppLocalizations.of(context)!.settingsAboutTitle,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.primaryGradient),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.settingsAppName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const Text('Version 1.0.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.settingsAboutDescription,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.warningDeep.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.warningDeep, size: 38),
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.settingsLogOutQuestion,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.settingsLogOutDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: AppLocalizations.of(context)!.settingsLogOutButton,
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  context.read<AppState>().signOut();
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: AppLocalizations.of(context)!.settingsCancelButton,
                outlined: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBright, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
