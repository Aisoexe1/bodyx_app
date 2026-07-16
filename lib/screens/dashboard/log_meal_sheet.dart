import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/food_database.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_colors.dart';
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

  void _addFood(FoodItem food) {
    HapticFeedback.mediumImpact();
    context.read<AppState>().logMeal(MealEntry(
          name: food.name,
          time: _timeLabel,
          kcal: food.kcal,
          proteinG: food.proteinG,
          carbsG: food.carbsG,
          fatG: food.fatG,
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
                  const Text('Приём пищи',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  StatChip(label: status.label, color: statusColor(status.level)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${state.todayCaloriesEaten} / ${state.tdee.round()} ккал сегодня',
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
                    _modeTab('Найти продукт', _LogMode.search),
                    _modeTab('Свой вариант', _LogMode.custom),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_mode == _LogMode.search) ...[
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Поиск продукта…',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Ничего не найдено — попробуй свой вариант',
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ...results.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScaleTap(
                          onTap: () => _addFood(f),
                          child: GlowCard(
                            child: Row(
                              children: [
                                GlowIconBadge(icon: f.icon, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.name,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5)),
                                      Text(
                                          '${f.serving} · ${f.kcal} ккал · ${f.proteinG}Б/${f.carbsG}У/${f.fatG}Ж',
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.add_circle_rounded,
                                    color: AppColors.primaryBright, size: 22),
                              ],
                            ),
                          ),
                        ),
                      )),
              ] else ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Название блюда'),
                ),
                const SizedBox(height: 14),
                _macroStepper('Калории', _kcal, 0, 1500, 10,
                    (v) => setState(() => _kcal = v)),
                const SizedBox(height: 10),
                _macroStepper('Белок (г)', _protein, 0, 150, 1,
                    (v) => setState(() => _protein = v)),
                const SizedBox(height: 10),
                _macroStepper('Углеводы (г)', _carbs, 0, 200, 1,
                    (v) => setState(() => _carbs = v)),
                const SizedBox(height: 10),
                _macroStepper(
                    'Жиры (г)', _fat, 0, 100, 1, (v) => setState(() => _fat = v)),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Добавить', onPressed: _addCustom),
              ],
              if (state.meals.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Сегодня',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
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
                                Text('${meal.time} · ${meal.kcal} ккал',
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
