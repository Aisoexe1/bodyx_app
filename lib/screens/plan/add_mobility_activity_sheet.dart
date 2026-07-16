import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/count_stepper.dart';
import '../../widgets/common/inputs_buttons.dart';

/// Lets the user add their own mobility/stretch activity to today's plan
/// — name and minutes, no fixed routine to pick from.
class AddMobilityActivitySheet extends StatefulWidget {
  const AddMobilityActivitySheet({super.key});

  @override
  State<AddMobilityActivitySheet> createState() =>
      _AddMobilityActivitySheetState();
}

class _AddMobilityActivitySheetState extends State<AddMobilityActivitySheet> {
  final _nameController = TextEditingController();
  int _minutes = 10;

  @override
  void initState() {
    super.initState();
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
    context.read<AppState>().addMobilityActivity(name, _minutes);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            const Text('Add Mobility Activity',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('E.g. hip flexor stretch, foam rolling, yoga flow.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 16),
            PrimaryTextField(
              label: 'Activity name (e.g. Hip flexor stretch)',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CountStepper(
              label: 'Minutes',
              value: _minutes,
              min: 1,
              max: 60,
              onChanged: (v) => setState(() => _minutes = v),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add $_minutes min to today\'s plan',
              onPressed: name.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
