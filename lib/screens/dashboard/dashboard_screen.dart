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
import '../body_metrics/body_metrics_screen.dart';
import '../body_metrics/log_metrics_sheet.dart';
import '../plan/daily_plan_screen.dart';
import '../plan/mobility_checklist_sheet.dart';
import '../plan/workout_checklist_sheet.dart';
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
                    name: user?.name ??
                        AppLocalizations.of(context)!.dashboardAthlete),
                const SizedBox(height: 24),
                _DailyOverviewCard(state: state, stats: stats),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.water_drop_rounded,
                        color: AppColors.info,
                        label: AppLocalizations.of(context)!.dashboardWaterLabel,
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
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.warning,
                        label: AppLocalizations.of(context)!.dashboardCaloriesLabel,
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
                SectionHeader(
                  title: AppLocalizations.of(context)!.dashboardActionForToday,
                  action: AppLocalizations.of(context)!.dashboardSeePlan,
                  onActionTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyPlanScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _TodayChecklistCard(state: state),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// One cohesive checklist card instead of separate floating cards per
/// item — groups today's real workout progress with the quick self-report
/// tasks under a single header showing overall completion, so items with
/// different interaction models (progress vs. checkbox) still read as one
/// coherent list rather than an unrelated pile of cards.
class _TodayChecklistCard extends StatelessWidget {
  const _TodayChecklistCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final workoutSets = state.todayWorkoutSets;
    final workoutDone = workoutSets.isNotEmpty &&
        state.todayWorkoutCompletedSets == workoutSets.length;
    final mobilityActivities = state.todayMobilityActivities;
    final mobilityDone = mobilityActivities.isNotEmpty &&
        state.todayMobilityCompletedCount == mobilityActivities.length;
    final weightDone = state.loggedWeightToday;
    final simpleTasks = state.planTasks;
    final doneCount = (workoutDone ? 1 : 0) +
        (mobilityDone ? 1 : 0) +
        (weightDone ? 1 : 0) +
        simpleTasks.where((t) => t.done).length;
    final totalCount = 3 + simpleTasks.length;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    AppLocalizations.of(context)!.dashboardTodaysChecklist,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              StatChip(
                label: AppLocalizations.of(context)!.dashboardDoneCount(
                    doneCount.toString(), totalCount.toString()),
                color: doneCount == totalCount
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ChecklistRow(
            icon: Icons.fitness_center_rounded,
            title: AppLocalizations.of(context)!.planTodaysWorkoutTitle,
            subtitle: workoutSets.isEmpty
                ? AppLocalizations.of(context)!.dashboardNoExercisesYet
                : AppLocalizations.of(context)!.dashboardWorkoutSetsProgress(
                    state.todayWorkoutCompletedSets.toString(),
                    workoutSets.length.toString(),
                  ),
            done: workoutDone,
            progress: workoutSets.isEmpty ? null : state.todayWorkoutProgress,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const WorkoutChecklistSheet(),
            ),
          ),
          const _ChecklistDivider(),
          _ChecklistRow(
            icon: Icons.self_improvement_rounded,
            title: AppLocalizations.of(context)!.planMobilityStretchTitle,
            subtitle: mobilityActivities.isEmpty
                ? AppLocalizations.of(context)!.dashboardNoActivitiesYet
                : AppLocalizations.of(context)!.planMobilityProgress(
                    state.todayMobilityCompletedCount.toString(),
                    mobilityActivities.length.toString(),
                  ),
            done: mobilityDone,
            progress:
                mobilityActivities.isEmpty ? null : state.todayMobilityProgress,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const MobilityChecklistSheet(),
            ),
          ),
          const _ChecklistDivider(),
          _ChecklistRow(
            icon: Icons.monitor_weight_rounded,
            title: AppLocalizations.of(context)!.dashboardLogBodyWeight,
            subtitle: weightDone
                ? AppLocalizations.of(context)!.dashboardLoggedToday
                : AppLocalizations.of(context)!.dashboardMorningCheckIn,
            done: weightDone,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const LogMetricsSheet(),
            ),
          ),
          for (var i = 0; i < simpleTasks.length; i++) ...[
            const _ChecklistDivider(),
            _ChecklistRow(
              icon: simpleTasks[i].icon,
              title: simpleTasks[i].title,
              subtitle: simpleTasks[i].subtitle,
              done: simpleTasks[i].done,
              onTap: () => context.read<AppState>().togglePlanTask(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistDivider extends StatelessWidget {
  const _ChecklistDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: AppColors.cardBorder),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: AppColors.textMuted,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12.5)),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress!.clamp(0, 1)),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => LinearProgressIndicator(
                        value: t,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(
                            done ? AppColors.success : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? AppColors.success : AppColors.textMuted,
          ),
        ],
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
              Text(AppLocalizations.of(context)!.dashboardGoodMorning,
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
                      AppLocalizations.of(context)!.dashboardCaloriesLabel,
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
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        const Spacer(),
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
    final latest = state.weightHistory.isEmpty ? null : state.weightHistory.last;
    final title = latest == null
        ? AppLocalizations.of(context)!.dashboardBodyScanEmptyTitle
        : AppLocalizations.of(context)!.dashboardBodyScanSummary(
            latest.kg.round().toString(), latest.bodyFatPct.toStringAsFixed(1));
    final subtitle = latest == null
        ? AppLocalizations.of(context)!.dashboardBodyScanEmptySubtitle
        : AppLocalizations.of(context)!.dashboardTapToViewFullReport;
    return ScaleTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BodyMetricsScreen()),
      ),
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
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
