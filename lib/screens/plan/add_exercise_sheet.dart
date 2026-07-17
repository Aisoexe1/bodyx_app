import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/count_stepper.dart';
import '../../widgets/common/inputs_buttons.dart';

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
            Text(AppLocalizations.of(context)!.addExerciseTitle,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            PrimaryTextField(
              label: AppLocalizations.of(context)!.addExerciseNameHint,
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CountStepper(
                    label: AppLocalizations.of(context)!.addExerciseSetsLabel,
                    value: _sets,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setState(() => _sets = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CountStepper(
                    label: AppLocalizations.of(context)!.addExerciseRepsLabel,
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
              label: AppLocalizations.of(context)!
                  .addExerciseSubmitButton(_sets.toString(), _reps.toString()),
              onPressed: name.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
