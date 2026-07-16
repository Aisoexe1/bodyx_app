import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';

/// A real, checkable set-by-set workout list — replaces the old static
/// "2 / 5 sets" label with something you actually tick off as you train.
class WorkoutChecklistSheet extends StatelessWidget {
  const WorkoutChecklistSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final workout = state.todayWorkout;

    // Group sets by exercise while preserving their overall index (needed
    // for AppState.toggleWorkoutSet, which addresses sets by flat index).
    final byExercise = <String, List<int>>{};
    for (var i = 0; i < workout.sets.length; i++) {
      byExercise.putIfAbsent(workout.sets[i].exercise, () => []).add(i);
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Row(
            children: [
              GlowIconBadge(icon: workout.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text(workout.subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                  AppLocalizations.of(context)!.workoutChecklistSetsProgress(
                      workout.completedCount.toString(),
                      workout.sets.length.toString()),
                  style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: workout.progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 7,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...byExercise.entries.map((entry) {
            final exercise = entry.key;
            final indices = entry.value;
            final targetReps = workout.sets[indices.first].targetReps;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      AppLocalizations.of(context)!
                          .workoutChecklistExerciseReps(
                              exercise, targetReps.toString()),
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: indices.map((i) {
                      final set = workout.sets[i];
                      return ScaleTap(
                        onTap: () =>
                            context.read<AppState>().toggleWorkoutSet(i),
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: set.done
                                ? AppColors.success.withValues(alpha: 0.16)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: set.done
                                    ? AppColors.success
                                    : AppColors.cardBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                set.done
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: set.done
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  AppLocalizations.of(context)!
                                      .workoutChecklistSetLabel(
                                          set.setNumber.toString()),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: set.done
                                          ? AppColors.success
                                          : AppColors.textMuted)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          if (workout.completedCount == workout.sets.length)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(AppLocalizations.of(context)!.workoutChecklistComplete,
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
