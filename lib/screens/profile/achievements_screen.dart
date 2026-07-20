import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/achievement_labels.dart';
import '../../models/achievements.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';

/// Rank summary + the full 20-entry achievement catalog, grouped by family,
/// locked entries dimmed with a progress readout, unlocked ones showing the
/// date earned.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    final counters = <AchievementFamily, int>{
      AchievementFamily.streak: state.longestStreak,
      AchievementFamily.workout: state.totalWorkoutsCompleted,
      AchievementFamily.mobility: state.totalMobilityCompleted,
      AchievementFamily.hydration: state.totalWaterGoalDaysMet,
      AchievementFamily.nutrition: state.totalMealsLogged,
    };

    final byFamily = <AchievementFamily, List<AchievementDef>>{};
    for (final def in kAchievementCatalog) {
      byFamily.putIfAbsent(def.family, () => []).add(def);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(l10n.achievementsScreenTitle,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
                children: [
                  _RankSummaryCard(
                    rank: state.rank,
                    points: state.achievementPoints,
                  ),
                  const SizedBox(height: 24),
                  for (final family in AchievementFamily.values) ...[
                    _FamilyLabel(family),
                    const SizedBox(height: 10),
                    _FamilyGrid(
                      defs: byFamily[family]!,
                      counter: counters[family]!,
                      unlockedIds: state.unlockedAchievementIds,
                      unlockedAt: state.achievementUnlockedAt,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankSummaryCard extends StatelessWidget {
  const _RankSummaryCard({required this.rank, required this.points});
  final Rank rank;
  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = rankColor(rank);
    final next = nextRank(rank);
    final start = rankStartThreshold(rank);
    final end = nextRankThreshold(rank);
    final progress = end == null
        ? 1.0
        : ((points - start) / (end - start)).clamp(0.0, 1.0);

    return GlowCard(
      glow: true,
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.military_tech_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.achievementsRankLabel,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    Text(rankName(context, rank),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ],
                ),
              ),
              Text(l10n.achievementsPointsLabel(points),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? l10n.achievementsMaxRank
                : l10n.achievementsNextRankProgress(
                    end! - points, rankName(context, next)),
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _FamilyLabel extends StatelessWidget {
  const _FamilyLabel(this.family);
  final AchievementFamily family;

  IconData get _icon => switch (family) {
        AchievementFamily.streak => Icons.local_fire_department_rounded,
        AchievementFamily.workout => Icons.fitness_center_rounded,
        AchievementFamily.mobility => Icons.self_improvement_rounded,
        AchievementFamily.hydration => Icons.water_drop_rounded,
        AchievementFamily.nutrition => Icons.restaurant_rounded,
      };

  String _label(AppLocalizations l10n) => switch (family) {
        AchievementFamily.streak => l10n.achievementsFamilyStreak,
        AchievementFamily.workout => l10n.achievementsFamilyWorkout,
        AchievementFamily.mobility => l10n.achievementsFamilyMobility,
        AchievementFamily.hydration => l10n.achievementsFamilyHydration,
        AchievementFamily.nutrition => l10n.achievementsFamilyNutrition,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(_icon, color: AppColors.primaryBright, size: 16),
        const SizedBox(width: 8),
        Text(_label(l10n),
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ],
    );
  }
}

class _FamilyGrid extends StatelessWidget {
  const _FamilyGrid({
    required this.defs,
    required this.counter,
    required this.unlockedIds,
    required this.unlockedAt,
  });

  final List<AchievementDef> defs;
  final int counter;
  final Set<String> unlockedIds;
  final Map<String, DateTime> unlockedAt;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: defs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, i) {
        final def = defs[i];
        final unlocked = unlockedIds.contains(def.id);
        return _AchievementTile(
          def: def,
          unlocked: unlocked,
          counter: counter,
          unlockedDate: unlockedAt[def.id],
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.def,
    required this.unlocked,
    required this.counter,
    required this.unlockedDate,
  });

  final AchievementDef def;
  final bool unlocked;
  final int counter;
  final DateTime? unlockedDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = unlocked ? tierColor(def.tier) : AppColors.textMuted;

    return GlowCard(
      borderColor: unlocked ? color.withValues(alpha: 0.5) : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(def.icon, color: color, size: 22),
                const Spacer(),
                if (!unlocked)
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textMuted, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(achievementTitle(context, def.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(achievementDescription(context, def.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
            const Spacer(),
            Text(
              unlocked
                  ? l10n.achievementsUnlockedOn(
                      _formatDate(unlockedDate ?? DateTime.now()))
                  : l10n.achievementsLockedProgress(
                      counter.clamp(0, def.threshold), def.threshold),
              style: TextStyle(
                  color: unlocked ? color : AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
