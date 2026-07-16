import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/charts/sleep_donut_chart.dart';
import '../../widgets/charts/steps_bar_chart.dart';
import '../../widgets/charts/weight_line_chart.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/progress_ring.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeIndex = 0; // 0 = Week, 1 = Month, 2 = Year

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final weightHistory = state.weightHistory;
    final first = weightHistory.first;
    final last = weightHistory.last;
    final delta = last.kg - first.kg;
    final stats = state.dailyStats;
    final windowed = _rangeIndex == 0
        ? _calendarWeek(stats)
        : stats; // Month/Year reuse the full mock window.
    final todayStats = stats.last;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('Progress',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Track how your metrics evolve over time',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 18),
                _RangeSelector(
                  index: _rangeIndex,
                  onChanged: (i) => setState(() => _rangeIndex = i),
                ),
                const SizedBox(height: 20),
                GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Weight',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const Spacer(),
                          StatChip(
                            label:
                                '${delta <= 0 ? '' : '+'}${delta.toStringAsFixed(1)} kg',
                            color: delta <= 0
                                ? AppColors.success
                                : AppColors.warning,
                            icon: delta <= 0
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${last.kg} kg',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 28)),
                      const SizedBox(height: 12),
                      WeightLineChart(entries: weightHistory),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RingStatCard(
                        label: 'Body fat',
                        value: '${last.bodyFatPct}%',
                        progress: (last.bodyFatPct / 30).clamp(0, 1),
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RingStatCard(
                        label: 'BMI',
                        value: (state.user?.bmi ?? 22.5).toStringAsFixed(1),
                        progress: (((state.user?.bmi ?? 22.5) - 15) / 20)
                            .clamp(0, 1),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                    title: 'Activity',
                    subtitle: '${windowed.length}-day step history'),
                const SizedBox(height: 12),
                GlowCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: StepsBarChart(
                      key: ValueKey(_rangeIndex),
                      stats: windowed,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Sleep', subtitle: "Today's breakdown"),
                const SizedBox(height: 12),
                GlowCard(
                  child: SleepBreakdownCard(
                    lightMinutes: todayStats.lightSleepMinutes,
                    deepMinutes: todayStats.deepSleepMinutes,
                    remMinutes: todayStats.remSleepMinutes,
                    awakeMinutes: todayStats.awakeMinutes,
                    ringSize: 140,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Reorders the trailing mock history into calendar order (Mon..Sun) for
  /// the week containing "today" (the last entry in [stats]), instead of a
  /// rolling 7-day window that can start on any weekday. Days later in the
  /// week than today (no data yet) get a zero-value placeholder so the bar
  /// chart still shows all 7 days in order.
  List<DailyStats> _calendarWeek(List<DailyStats> stats) {
    final today = stats.last;
    final monday =
        today.date.subtract(Duration(days: today.date.weekday - 1));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return stats.firstWhere(
        (s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day,
        orElse: () => DailyStats(
          date: day,
          steps: 0,
          stepGoal: today.stepGoal,
          calories: 0,
          calorieGoal: today.calorieGoal,
          sleepMinutes: 0,
          sleepGoalMinutes: today.sleepGoalMinutes,
          waterMl: 0,
          waterGoalMl: today.waterGoalMl,
          lightSleepMinutes: 0,
          deepSleepMinutes: 0,
          remSleepMinutes: 0,
          awakeMinutes: 0,
        ),
      );
    });
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RingStatCard extends StatelessWidget {
  const _RingStatCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 10),
          ProgressRing(
            progress: progress,
            size: 84,
            strokeWidth: 8,
            color: color,
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
