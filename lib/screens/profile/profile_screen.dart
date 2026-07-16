import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';
import '../body_metrics/body_metrics_screen.dart';
import '../settings/settings_detail_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('Profile',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 20),
                GlowCard(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: AppColors.primaryGradient),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty ?? false)
                                ? user!.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? 'Athlete',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text('@${user?.username ?? 'athlete'}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _StatPill(
                                  label: 'Height',
                                  value:
                                      '${user?.heightCm.toStringAsFixed(0) ?? '--'} cm')),
                          Expanded(
                              child: _StatPill(
                                  label: 'Weight',
                                  value:
                                      '${user?.weightKg.toStringAsFixed(0) ?? '--'} kg')),
                          Expanded(
                              child: _StatPill(
                                  label: 'Age',
                                  value: '${user?.age ?? '--'}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ScaleTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Text('Edit profile',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _GroupLabel('ACCOUNT'),
                _SettingsGroup(rows: [
                  _RowSpec(Icons.badge_outlined, 'Personal data', '',
                      (ctx) => const PersonalDataScreen()),
                  _RowSpec(Icons.accessibility_new_rounded, 'Body metrics', '',
                      (ctx) => const BodyMetricsScreen()),
                  _RowSpec(Icons.flag_rounded, 'Goal', user?.goal ?? '—',
                      (ctx) => const GoalScreen()),
                ]),
                const SizedBox(height: 20),
                const _GroupLabel('PREFERENCES'),
                _SettingsGroup(rows: [
                  _RowSpec(Icons.notifications_outlined, 'Notifications', '',
                      (ctx) => const NotificationsScreen()),
                  _RowSpec(Icons.favorite_border_rounded, 'Health sync', '',
                      (ctx) => const HealthSyncScreen()),
                  _RowSpec(Icons.language_rounded, 'Units & language', '',
                      (ctx) => const UnitsLanguageScreen()),
                ]),
                const SizedBox(height: 20),
                const _GroupLabel('SUPPORT'),
                _SettingsGroup(rows: [
                  _RowSpec(Icons.privacy_tip_outlined, 'Privacy', '',
                      (ctx) => const PrivacyScreen()),
                  _RowSpec(Icons.help_outline_rounded, 'Help & support', '',
                      (ctx) => const HelpSupportScreen()),
                  _RowSpec(Icons.info_outline_rounded, 'About', '',
                      (ctx) => const AboutScreen()),
                ]),
                const SizedBox(height: 20),
                ScaleTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogoutScreen()),
                  ),
                  child: const GlowCard(
                    borderColor: AppColors.warningDeep,
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.warningDeep),
                        SizedBox(width: 12),
                        Text('Log out',
                            style: TextStyle(
                                color: AppColors.warningDeep,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _RowSpec {
  _RowSpec(this.icon, this.label, this.value, this.builder);
  final IconData icon;
  final String label;
  final String value;
  final WidgetBuilder builder;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});
  final List<_RowSpec> rows;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          return Column(
            children: [
              ScaleTap(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: r.builder),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 14),
                  child: Row(
                    children: [
                      Icon(r.icon, color: AppColors.primaryBright, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(r.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      if (r.value.isNotEmpty)
                        Text(r.value,
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
                const Divider(height: 1, color: AppColors.divider, indent: AppSpacing.md, endIndent: AppSpacing.md),
            ],
          );
        }),
      ),
    );
  }
}
