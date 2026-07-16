import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/count_up_text.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/scale_tap.dart';
import '../body_metrics/body_metrics_screen.dart';
import '../plan/daily_plan_screen.dart';

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
                _GreetingRow(name: user?.name ?? 'Athlete'),
                const SizedBox(height: 24),
                _DailyOverviewCard(state: state, stats: stats),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.water_drop_rounded,
                        color: AppColors.info,
                        label: 'Water',
                        value: CountUpText(
                          value: stats.waterMl,
                          formatter: (v) => '${(v / 1000).toStringAsFixed(1)}L',
                          style: _MiniStatCard.valueStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.favorite_rounded,
                        color: AppColors.pink,
                        label: 'Heart rate',
                        value: CountUpText(
                          value: stats.heartRateBpm,
                          formatter: (v) => '$v bpm',
                          style: _MiniStatCard.valueStyle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Last body scan'),
                const SizedBox(height: 12),
                _LastBodyScanCard(state: state),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Action for today',
                  action: 'See plan',
                  onActionTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyPlanScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(state.planTasks.length, (i) {
                  final task = state.planTasks[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ScaleTap(
                      onTap: () => context.read<AppState>().togglePlanTask(i),
                      child: GlowCard(
                        child: Row(
                          children: [
                            GlowIconBadge(
                              icon: task.icon,
                              color: task.done
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        decoration: task.done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor: AppColors.textMuted,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(task.subtitle,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Icon(
                              task.done
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: task.done
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ),
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
              const Text('Good morning',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
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
          const Text('Daily overview',
              style: TextStyle(
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
                      'Steps',
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountUpText(value: stats.steps, style: _valueStyle),
                          Text(' / ${stats.stepGoal}', style: _valueStyle),
                        ],
                      ),
                      AppColors.primaryBright,
                    ),
                    const SizedBox(height: 10),
                    _statLine(
                      Icons.local_fire_department_rounded,
                      'Calories',
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
                      'Sleep',
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
  });

  static const valueStyle = TextStyle(
      color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14);

  final IconData icon;
  final Color color;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Row(
        children: [
          GlowIconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value,
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastBodyScanCard extends StatelessWidget {
  const _LastBodyScanCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.weightHistory.last;
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
                  Text('${latest.kg} kg  •  ${latest.bodyFatPct}% BF',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Tap to view full report',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
