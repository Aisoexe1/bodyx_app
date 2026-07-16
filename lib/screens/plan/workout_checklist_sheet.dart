import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import 'add_exercise_sheet.dart';

/// A real, checkable set-by-set workout list built entirely by the user —
/// no fixed template. Starts empty; exercises are added on demand, each
/// set is individually tappable, and a start/stop timer tracks how long
/// the session actually took.
class WorkoutChecklistSheet extends StatefulWidget {
  const WorkoutChecklistSheet({super.key});

  @override
  State<WorkoutChecklistSheet> createState() => _WorkoutChecklistSheetState();
}

class _WorkoutChecklistSheetState extends State<WorkoutChecklistSheet> {
  // Ticks once a second so the elapsed-time display stays live while the
  // sheet is open — AppState only notifies on start/stop, not every
  // second, since the elapsed duration is derived (now - startedAt), not
  // stored state. Started eagerly in initState — a `late` field initialized
  // by this same expression would only run on first *read*, which here
  // would be inside dispose(), never actually ticking.
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _openAddExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExerciseSheet(),
    );
  }

  Future<void> _confirmRemoveExercise(String exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Remove $exercise?',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text('This removes all of its sets from today.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.warningDeep)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AppState>().removeExercise(exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sets = state.todayWorkoutSets;

    // Group sets by exercise while preserving their overall index (needed
    // for AppState.toggleWorkoutSet, which addresses sets by flat index),
    // in the order each exercise was first added.
    final byExercise = <String, List<int>>{};
    for (var i = 0; i < sets.length; i++) {
      byExercise.putIfAbsent(sets[i].exercise, () => []).add(i);
    }

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Column(
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
                    const GlowIconBadge(icon: Icons.fitness_center_rounded),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("Today's Workout",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (sets.isNotEmpty)
                      Text(
                          '${state.todayWorkoutCompletedSets} / ${sets.length}',
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 14),
                _TimerBar(
                  elapsed: state.todayWorkoutElapsed,
                  running: state.isWorkoutTimerRunning,
                  onToggle: () =>
                      context.read<AppState>().toggleWorkoutTimer(),
                ),
                if (sets.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: state.todayWorkoutProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => LinearProgressIndicator(
                        value: t,
                        minHeight: 7,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 16, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sets.isEmpty)
                    _EmptyWorkoutState(onAdd: _openAddExercise)
                  else ...[
                    ...byExercise.entries.map((entry) {
                      final exercise = entry.key;
                      final indices = entry.value;
                      final targetReps = sets[indices.first].targetReps;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('$exercise · $targetReps reps',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5)),
                                ),
                                ScaleTap(
                                  onTap: () =>
                                      _confirmRemoveExercise(exercise),
                                  child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: indices.map((i) {
                                final set = sets[i];
                                return ScaleTap(
                                  onTap: () => context
                                      .read<AppState>()
                                      .toggleWorkoutSet(i),
                                  child: Container(
                                    width: 64,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: set.done
                                          ? AppColors.success
                                              .withValues(alpha: 0.16)
                                          : AppColors.card,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
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
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          color: set.done
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Set ${set.setNumber}',
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
                    ScaleTap(
                      onTap: _openAddExercise,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text('+ Add another exercise',
                            style: TextStyle(
                                color: AppColors.primaryBright,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (state.todayWorkoutCompletedSets == sets.length) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Text('Workout complete 💪',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.elapsed,
    required this.running,
    required this.onToggle,
  });

  final Duration elapsed;
  final bool running;
  final VoidCallback onToggle;

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: running
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: running ? AppColors.success : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 18,
              color: running ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_format(elapsed),
                style: TextStyle(
                    color: running
                        ? AppColors.success
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          ScaleTap(
            onTap: onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: running ? AppColors.warningDeep : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(running ? 'Stop' : 'Start',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.playlist_add_rounded,
              color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          const Text('No exercises yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Add what you\'re training today — name, sets, reps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Add exercise', onPressed: onAdd),
        ],
      ),
    );
  }
}
