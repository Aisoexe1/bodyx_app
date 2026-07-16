import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

/// Shared chrome for every settings sub-screen: back button + title,
/// scrollable body.
class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
      title: 'Edit profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryTextField(label: 'Full name', controller: _name),
          const SizedBox(height: 14),
          PrimaryTextField(
              label: 'Username',
              controller: _username,
              prefixIcon: Icons.alternate_email_rounded),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save changes',
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
      (Icons.straighten_rounded, 'Height',
          '${user?.heightCm.toStringAsFixed(0) ?? '--'} cm',
          (ctx) => const EditHeightScreen()),
      (Icons.monitor_weight_outlined, 'Weight',
          '${user?.weightKg.toStringAsFixed(0) ?? '--'} kg',
          (ctx) => const EditWeightScreen()),
      (Icons.cake_outlined, 'Age', '${user?.age ?? '--'}',
          (ctx) => const EditAgeScreen()),
      (Icons.wc_rounded, 'Gender', user?.gender.name ?? 'male',
          (ctx) => const EditGenderScreen()),
    ];

    return _SettingsScaffold(
      title: 'Personal data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This data helps us personalize your plan and recommendations.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
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
            label: 'Save',
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
      title: 'Edit height',
      unit: 'cm',
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
      title: 'Edit weight',
      unit: 'kg',
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
      title: 'Edit age',
      unit: 'yrs',
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
      title: 'Edit gender',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _choiceCard('Male', Icons.male_rounded, Gender.male,
                    AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _choiceCard('Female', Icons.female_rounded,
                    Gender.female, AppColors.pink),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save',
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
      title: 'Your goal',
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
                          child: Text(g.$1,
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
            label: 'Save goal',
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: 'Notifications',
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.notifications_active_outlined,
            label: 'Push notifications',
            value: state.notificationsEnabled,
            onChanged: (v) => context.read<AppState>().toggleNotifications(v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.fitness_center_rounded,
            label: 'Workout reminders',
            value: state.workoutRemindersEnabled,
            onChanged: (v) =>
                context.read<AppState>().toggleWorkoutReminders(v),
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
        return 'Apple Health';
      case TargetPlatform.android:
        return 'Health Connect';
      default:
        return 'Health app';
    }
  }

  Future<void> _handleToggle(bool value) async {
    final granted = await context.read<AppState>().toggleHealthSync(value);
    if (!mounted) return;
    if (value && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_platformLabel access was not granted.')),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    HapticFeedback.mediumImpact();
    await context.read<AppState>().syncHealthData();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Synced with $_platformLabel.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _SettingsScaffold(
      title: 'Health sync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleRow(
            icon: Icons.favorite_border_rounded,
            label: 'Sync with $_platformLabel',
            value: state.healthSyncEnabled,
            onChanged: (v) => _handleToggle(v),
          ),
          const SizedBox(height: 14),
          const Text(
            'Reads steps, calories, sleep, water, weight and heart rate to '
            'keep your dashboard accurate. BodyX never writes data back.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (state.healthSyncEnabled) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Sync now',
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
      title: 'Units & language',
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.straighten_rounded,
            label: 'Use metric units (cm / kg)',
            value: state.user?.unitsMetric ?? true,
            onChanged: (_) => context.read<AppState>().toggleUnits(),
          ),
          const SizedBox(height: 10),
          const GlowCard(
            child: Row(
              children: [
                Icon(Icons.language_rounded, color: AppColors.primaryBright),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Language',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                Text('English (US)',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
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
  bool _publicProfile = false;
  bool _shareAnonData = true;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Privacy',
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.public_rounded,
            label: 'Public profile',
            value: _publicProfile,
            onChanged: (v) => setState(() => _publicProfile = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            icon: Icons.analytics_outlined,
            label: 'Share anonymous usage data',
            value: _shareAnonData,
            onChanged: (v) => setState(() => _shareAnonData = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Delete account',
              outlined: true,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete account?',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text(
                      'This is a prototype — no data will actually be deleted.',
                      style: TextStyle(color: AppColors.textMuted)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                  ],
                ),
              ),
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
    'How is my body scan calculated?',
    'How do I sync a wearable device?',
    'Can I export my progress data?',
    'How do I change my daily goals?',
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Help & support',
      child: Column(
        children: [
          const GlowCard(
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.primaryBright),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Contact support',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('FREQUENTLY ASKED',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          ..._faqs.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(q,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13.5))),
                      const Icon(Icons.expand_more_rounded,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'About BodyX',
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
          const Text('BodyX',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const Text('Version 1.0.0 (prototype)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BodyX helps you track training, sleep, nutrition and '
                    'body composition in one premium, dark-neon experience.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
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
      backgroundColor: Colors.transparent,
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
              const Text('Log out?',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                'You can always sign back in with your email and password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Log out',
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  context.read<AppState>().signOut();
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Cancel',
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
