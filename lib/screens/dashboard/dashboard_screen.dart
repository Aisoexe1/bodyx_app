import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_colors.dart';
import '../../widgets/common/count_up_text.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/scale_tap.dart';
import '../../widgets/pet/dragon_avatar.dart';
import '../body_metrics/log_metrics_sheet.dart';
import '../pet/pet_screen.dart';
import 'log_meal_sheet.dart';
import 'water_log_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.selectedStats;
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
                _GreetingRow(
                    name: user?.username ??
                        AppLocalizations.of(context)!.dashboardAthlete),
                for (final announcement in state.activeAnnouncements) ...[
                  const SizedBox(height: 14),
                  _AnnouncementBanner(
                    announcement: announcement,
                    onDismiss: () => context
                        .read<AppState>()
                        .dismissAnnouncement(announcement.id),
                  ),
                ],
                const SizedBox(height: 14),
                _PetCard(state: state),
                const SizedBox(height: 24),
                _DailyOverviewCard(state: state, stats: stats),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.water_drop_rounded,
                        color: AppColors.info,
                        label:
                            AppLocalizations.of(context)!.dashboardWaterLabel,
                        value: CountUpText(
                          value: stats.waterMl,
                          formatter: (v) => '${(v / 1000).toStringAsFixed(1)}L',
                          style: _MiniStatCard.valueStyle,
                        ),
                        statusDot: state.selectedDateIndex == -1
                            ? statusColor(state.todayWaterStatus.level)
                            : null,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const WaterLogSheet(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.restaurant_rounded,
                        color: AppColors.warning,
                        label: AppLocalizations.of(context)!
                            .dashboardCaloriesEatenLabel,
                        value: CountUpText(
                          value: state.todayCaloriesEaten,
                          formatter: (v) => '$v kcal',
                          style: _MiniStatCard.valueStyle,
                        ),
                        statusDot: state.selectedDateIndex == -1
                            ? statusColor(state.calorieSurplusStatus.level)
                            : null,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const LogMealSheet(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                    title: AppLocalizations.of(context)!.dashboardLastBodyScan),
                const SizedBox(height: 12),
                _LastBodyScanCard(state: state),
                const SizedBox(height: 24),
                _TodayShortcuts(state: state),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact link into today's structured plan plus the one daily nudge
/// that has no home elsewhere (weigh-in) — Plan (the tab) now owns the
/// actual workout/mobility checklist, so this is a teaser, not a copy of
/// it: no set counts, no progress bars, just "is there something to do."
class _TodayShortcuts extends StatelessWidget {
  const _TodayShortcuts({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workoutSets = state.todayWorkoutSets;
    final workoutDone = workoutSets.isNotEmpty &&
        state.todayWorkoutCompletedSets == workoutSets.length;
    final mobilityActivities = state.todayMobilityActivities;
    final mobilityDone = mobilityActivities.isNotEmpty &&
        state.todayMobilityCompletedCount == mobilityActivities.length;
    final planStarted = workoutSets.isNotEmpty || mobilityActivities.isNotEmpty;
    final planDone = planStarted &&
        (workoutSets.isEmpty || workoutDone) &&
        (mobilityActivities.isEmpty || mobilityDone);
    final weightDone = state.loggedWeightToday;

    return GlowCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ShortcutRow(
            icon: Icons.checklist_rounded,
            title: l10n.dashboardTodaysPlanLabel,
            subtitle: !planStarted
                ? l10n.dashboardTodaysPlanEmptyHint
                : planDone
                    ? l10n.planDoneLabel
                    : l10n.planInProgressLabel,
            done: planDone,
            onTap: () => context.read<AppState>().selectNav(2),
          ),
          const Divider(
              height: 1,
              color: AppColors.divider,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md),
          _ShortcutRow(
            icon: Icons.monitor_weight_rounded,
            title: l10n.dashboardLogBodyWeight,
            subtitle: weightDone
                ? l10n.dashboardLoggedToday
                : l10n.dashboardMorningCheckIn,
            done: weightDone,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const LogMetricsSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            GlowIconBadge(
              icon: icon,
              color: done ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: done ? AppColors.success : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: AppColors.primaryGradient),
          ),
          child: Center(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(AppLocalizations.of(context)!),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5)),
              Text(name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  /// Time-of-day greeting so it doesn't say "good morning" at 9pm — bucketed
  /// by the device's local hour, re-evaluated on every rebuild rather than
  /// cached, since the dashboard can stay open across a bucket boundary.
  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.dashboardGoodMorning;
    if (hour >= 12 && hour < 17) return l10n.dashboardGoodAfternoon;
    if (hour >= 17 && hour < 22) return l10n.dashboardGoodEvening;
    return l10n.dashboardGoodNight;
  }
}

/// An admin-broadcast banner (see the Announcements view in /admin) —
/// dismissible per device, never re-shown once closed on this install.
class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({
    required this.announcement,
    required this.onDismiss,
  });

  final Announcement announcement;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryDeep),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded,
              color: AppColors.primaryBright, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(announcement.message,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, height: 1.35)),
          ),
          const SizedBox(width: 6),
          ScaleTap(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Compact tamagotchi-style summary — grows from real goal completion (see
/// [AppState.todayPetGoals]), tap through to [PetScreen] for the full view.
class _PetCard extends StatelessWidget {
  const _PetCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetScreen()),
      ),
      child: GlowCard(
        child: Row(
          children: [
            DragonAvatar(stage: state.petStage, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.petCardTitle,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(l10n.petLevelShort(state.petLevel),
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: state.petLevelProgress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primaryBright),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.petXpProgress(state.petXpIntoLevel.toString()),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DailyOverviewCard extends StatelessWidget {
  const _DailyOverviewCard({required this.state, required this.stats});
  final AppState state;
  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceElevated, AppColors.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.dashboardDailyOverview,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 18),
          Row(
            children: [
              ProgressRing(
                progress: stats.stepProgress,
                size: 92,
                strokeWidth: 9,
                celebrateOnComplete: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk_rounded,
                        color: AppColors.primaryBright, size: 16),
                    CountUpText(
                      value: stats.steps,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statLine(
                      Icons.directions_walk_rounded,
                      AppLocalizations.of(context)!.dashboardStepsLabel,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountUpText(value: stats.steps, style: _valueStyle),
                          Text(
                              AppLocalizations.of(context)!
                                  .dashboardStepGoalSuffix(
                                      stats.stepGoal.toString()),
                              style: _valueStyle),
                        ],
                      ),
                      AppColors.primaryBright,
                    ),
                    const SizedBox(height: 10),
                    _statLine(
                      Icons.local_fire_department_rounded,
                      AppLocalizations.of(context)!
                          .dashboardCaloriesBurnedLabel,
                      CountUpText(
                        value: stats.calories,
                        formatter: (v) => '$v kcal',
                        style: _valueStyle,
                      ),
                      AppColors.warning,
                    ),
                    const SizedBox(height: 10),
                    _statLine(
                      Icons.bedtime_rounded,
                      AppLocalizations.of(context)!.dashboardSleepLabel,
                      CountUpText(
                        value: stats.sleepMinutes,
                        formatter: (v) => '${v ~/ 60}h ${v % 60}m',
                        style: _valueStyle,
                      ),
                      AppColors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _valueStyle = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 12.5);

  Widget _statLine(IconData icon, String label, Widget value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
        const SizedBox(width: 6),
        value,
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.statusDot,
    this.onTap,
  });

  static const valueStyle = TextStyle(
      color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14);

  final IconData icon;
  final Color color;
  final String label;
  final Widget value;
  final Color? statusDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = GlowCard(
      child: Row(
        children: [
          GlowIconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value,
                Row(
                  children: [
                    if (statusDot != null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                            color: statusDot, shape: BoxShape.circle),
                      ),
                    ],
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return onTap == null ? card : ScaleTap(onTap: onTap!, child: card);
  }
}

class _LastBodyScanCard extends StatelessWidget {
  const _LastBodyScanCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    // Empty until the user logs their first weigh-in (or Health sync pulls
    // one in) — a brand new account has no entries yet, so this can't
    // assume there's always a `.last` to show.
    final latest =
        state.weightHistory.isEmpty ? null : state.weightHistory.last;
    final title = latest == null
        ? AppLocalizations.of(context)!.dashboardBodyScanEmptyTitle
        : AppLocalizations.of(context)!.dashboardBodyScanSummary(
            latest.kg.round().toString(), latest.bodyFatPct.toStringAsFixed(1));
    final subtitle = latest == null
        ? AppLocalizations.of(context)!.dashboardBodyScanEmptySubtitle
        : AppLocalizations.of(context)!.dashboardTapToViewFullReport;
    return ScaleTap(
      // Weight/body-fat detail lives on the Progress tab, not Body
      // Metrics (that screen is circumference-only) — this switches tabs
      // rather than pushing a screen since Progress is a bottom-nav tab.
      onTap: () => context.read<AppState>().selectNav(1),
      child: GlowCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.accessibility_new_rounded,
                  color: AppColors.primaryBright, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
