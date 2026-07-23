import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import '../../widgets/common/timer_bar.dart';
import 'add_exercise_sheet.dart';
import 'rpe_picker_sheet.dart';

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
    final confirmed = await showConfirmDialog(
      context,
      title: AppLocalizations.of(context)!
          .workoutChecklistRemoveExerciseTitle(exercise),
      message:
          AppLocalizations.of(context)!.workoutChecklistRemoveExerciseContent,
      confirmLabel: AppLocalizations.of(context)!.workoutChecklistRemoveButton,
      cancelLabel: AppLocalizations.of(context)!.settingsCancelButton,
    );
    if (confirmed && mounted) {
      context.read<AppState>().removeExercise(exercise);
    }
  }

  /// Toggles [index]'s done state; if that just marked it done, immediately
  /// asks for an RPE rating. Re-tapping an already-rated done set (rather
  /// than un-checking it) is handled separately via long-press, so a single
  /// tap always means "toggle done" — consistent with the pre-existing tap
  /// semantics on this chip.
  Future<void> _toggleSet(int index) async {
    final appState = context.read<AppState>();
    appState.toggleWorkoutSet(index);
    final set = appState.todayWorkoutSets[index];
    if (!set.done) return;
    final rpe = await showRpePicker(context, initialRpe: set.rpe);
    if (rpe != null && mounted) {
      appState.setWorkoutSetRpe(index, rpe);
    }
  }

  Future<void> _editRpe(int index) async {
    final appState = context.read<AppState>();
    final current = appState.todayWorkoutSets[index].rpe;
    final rpe = await showRpePicker(context, initialRpe: current);
    if (rpe != null && mounted) {
      appState.setWorkoutSetRpe(index, rpe);
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
                    Expanded(
                      child: Text(
                          AppLocalizations.of(context)!
                              .planTodaysWorkoutTitle,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (sets.isNotEmpty)
                      Text(
                          AppLocalizations.of(context)!
                              .workoutChecklistSetsProgress(
                            state.todayWorkoutCompletedSets.toString(),
                            sets.length.toString(),
                          ),
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 14),
                TimerBar(
                  elapsed: state.todayWorkoutElapsed,
                  running: state.isWorkoutTimerRunning,
                  onToggle: () =>
                      context.read<AppState>().toggleWorkoutTimer(),
                  onReset: () =>
                      context.read<AppState>().resetWorkoutTimer(),
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
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .workoutChecklistExerciseReps(
                                              exercise, targetReps.toString()),
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
                                  onTap: () => _toggleSet(i),
                                  onLongPress:
                                      set.done ? () => _editRpe(i) : null,
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
                                        if (set.done && set.rpe != null) ...[
                                          const SizedBox(height: 2),
                                          Text('RPE ${set.rpe}',
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textMuted)),
                                        ],
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
                        child: Text(
                            AppLocalizations.of(context)!
                                .workoutChecklistAddAnotherExercise,
                            style: const TextStyle(
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
                        child: Text(
                            AppLocalizations.of(context)!
                                .workoutChecklistComplete,
                            style: const TextStyle(
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
          Text(AppLocalizations.of(context)!.workoutChecklistEmptyTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(
              AppLocalizations.of(context)!.workoutChecklistEmptyDescription,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 18),
          PrimaryButton(
              label:
                  AppLocalizations.of(context)!.workoutChecklistAddExerciseButton,
              onPressed: onAdd),
        ],
      ),
    );
  }
}
