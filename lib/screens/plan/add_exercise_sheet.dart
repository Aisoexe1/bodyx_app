import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

/// Lets the user add their own exercise to today's workout — name, how
/// many sets, and the target reps per set. There's no exercise database
/// or fixed template to pick from; whatever they type is what gets
/// tracked.
class AddExerciseSheet extends StatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _nameController = TextEditingController();
  int _sets = 3;
  int _reps = 10;

  @override
  void initState() {
    super.initState();
    // Re-render on every keystroke so the Add button enables the moment
    // the name field stops being empty.
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<AppState>().addExercise(name, _sets, _reps);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            const Text('Add Exercise',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            PrimaryTextField(
              label: 'Exercise name (e.g. Bench Press)',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CountStepper(
                    label: 'Sets',
                    value: _sets,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setState(() => _sets = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountStepper(
                    label: 'Reps',
                    value: _reps,
                    min: 1,
                    max: 50,
                    onChanged: (v) => setState(() => _reps = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add $_sets × $_reps to today\'s workout',
              onPressed: name.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleTap(
                onTap: value > min ? () => onChanged(value - 1) : null,
                child: const Icon(Icons.remove_circle_outline_rounded,
                    color: AppColors.textMuted),
              ),
              Text('$value',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              ScaleTap(
                onTap: value < max ? () => onChanged(value + 1) : null,
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primaryBright),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
