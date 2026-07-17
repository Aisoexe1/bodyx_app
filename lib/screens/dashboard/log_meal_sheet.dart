import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../data/food_database.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_colors.dart';
import '../../widgets/common/count_stepper.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

enum _LogMode { search, custom }

/// Meal logging — search a small local food list (no external API/barcode
/// service available in this prototype) or enter a custom item, plus
/// today's already-logged meals with a way to remove one.
class LogMealSheet extends StatefulWidget {
  const LogMealSheet({super.key});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  _LogMode _mode = _LogMode.search;
  String _query = '';
  final _nameController = TextEditingController();
  double _kcal = 300;
  double _protein = 20;
  double _carbs = 30;
  double _fat = 10;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openGramPicker(FoodItem food) async {
    HapticFeedback.selectionClick();
    final grams = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GramPickerSheet(food: food),
    );
    if (grams == null || !mounted) return;
    HapticFeedback.mediumImpact();
    context.read<AppState>().logMeal(MealEntry(
          name: food.name,
          time: _timeLabel,
          kcal: food.kcalFor(grams),
          proteinG: food.proteinFor(grams),
          carbsG: food.carbsFor(grams),
          fatG: food.fatFor(grams),
          icon: food.icon,
        ));
  }

  void _addCustom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    context.read<AppState>().logMeal(MealEntry(
          name: name,
          time: _timeLabel,
          kcal: _kcal.round(),
          proteinG: _protein.round(),
          carbsG: _carbs.round(),
          fatG: _fat.round(),
          icon: Icons.restaurant_rounded,
        ));
    _nameController.clear();
    setState(() {
      _kcal = 300;
      _protein = 20;
      _carbs = 30;
      _fat = 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.calorieSurplusStatus;
    final results = FoodDatabase.search(_query);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
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
                  Text(AppLocalizations.of(context)!.logMealTitle,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  StatChip(label: status.label, color: statusColor(status.level)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.logMealCaloriesToday(
                    state.todayCaloriesEaten.toString(),
                    state.tdee.round().toString()),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _modeTab(AppLocalizations.of(context)!.logMealSearchTab,
                        _LogMode.search),
                    _modeTab(AppLocalizations.of(context)!.logMealCustomTab,
                        _LogMode.custom),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_mode == _LogMode.search) ...[
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.logMealSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(AppLocalizations.of(context)!.logMealNoResults,
                        style: const TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ...FoodDatabase.grouped(results).expand((group) => [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                          child: Row(
                            children: [
                              Icon(group.key.icon,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(group.key.label,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                        ...group.value.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ScaleTap(
                                onTap: () => _openGramPicker(f),
                                child: GlowCard(
                                  child: Row(
                                    children: [
                                      GlowIconBadge(icon: f.icon, size: 34),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(f.name,
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 13.5)),
                                            Text(
                                                '${f.defaultGrams} г · ${f.kcalFor(f.defaultGrams)} ккал · '
                                                '${f.proteinFor(f.defaultGrams)}Б/${f.carbsFor(f.defaultGrams)}У/${f.fatFor(f.defaultGrams)}Ж',
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textMuted,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.add_circle_rounded,
                                          color: AppColors.primaryBright,
                                          size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ]),
              ] else ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.logMealNameHint),
                ),
                const SizedBox(height: 14),
                _macroStepper(AppLocalizations.of(context)!.logMealCaloriesLabel,
                    _kcal, 0, 1500, 10, (v) => setState(() => _kcal = v)),
                const SizedBox(height: 10),
                _macroStepper(AppLocalizations.of(context)!.logMealProteinLabel,
                    _protein, 0, 150, 1, (v) => setState(() => _protein = v)),
                const SizedBox(height: 10),
                _macroStepper(AppLocalizations.of(context)!.logMealCarbsLabel,
                    _carbs, 0, 200, 1, (v) => setState(() => _carbs = v)),
                const SizedBox(height: 10),
                _macroStepper(AppLocalizations.of(context)!.logMealFatLabel, _fat,
                    0, 100, 1, (v) => setState(() => _fat = v)),
                const SizedBox(height: 16),
                PrimaryButton(
                    label: AppLocalizations.of(context)!.logMealAddButton,
                    onPressed: _addCustom),
              ],
              if (state.meals.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.logMealTodayLabel,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 8),
                ...List.generate(state.meals.length, (i) {
                  final meal = state.meals[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlowCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 10),
                      child: Row(
                        children: [
                          Icon(meal.icon, color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(meal.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5)),
                                Text(
                                    AppLocalizations.of(context)!
                                        .logMealTimeKcal(meal.time,
                                            meal.kcal.toString()),
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<AppState>().removeMeal(i),
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _modeTab(String label, _LogMode mode) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _macroStepper(String label, double value, double min, double max,
      double step, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
        IconButton(
          onPressed: () => onChanged((value - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline_rounded,
              color: AppColors.textMuted, size: 20),
        ),
        SizedBox(
          width: 40,
          child: Text(value.round().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
        IconButton(
          onPressed: () => onChanged((value + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline_rounded,
              color: AppColors.primaryBright, size: 20),
        ),
      ],
    );
  }
}

/// Lets the user dial in exactly how much of a food they actually ate
/// before logging it — macros are computed live from the food's per-100g
/// values, so the numbers stay accurate at any amount instead of being
/// locked to one fixed serving size.
class _GramPickerSheet extends StatefulWidget {
  const _GramPickerSheet({required this.food});
  final FoodItem food;

  @override
  State<_GramPickerSheet> createState() => _GramPickerSheetState();
}

class _GramPickerSheetState extends State<_GramPickerSheet> {
  late int _grams = widget.food.defaultGrams;

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                GlowIconBadge(icon: food.icon, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(food.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            CountStepper(
              label:
                  AppLocalizations.of(context)!.logMealGramsLabel,
              value: _grams,
              min: 10,
              max: 1000,
              step: 10,
              onChanged: (v) => setState(() => _grams = v),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroPreview(AppLocalizations.of(context)!.logMealCaloriesLabel,
                    '${food.kcalFor(_grams)}'),
                _macroPreview(AppLocalizations.of(context)!.logMealProteinLabel,
                    '${food.proteinFor(_grams)}г'),
                _macroPreview(AppLocalizations.of(context)!.logMealCarbsLabel,
                    '${food.carbsFor(_grams)}г'),
                _macroPreview(AppLocalizations.of(context)!.logMealFatLabel,
                    '${food.fatFor(_grams)}г'),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: AppLocalizations.of(context)!.logMealAddButton,
              onPressed: () => Navigator.pop(context, _grams),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroPreview(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
      ],
    );
  }
}
