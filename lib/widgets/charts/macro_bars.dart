import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class MacroBars extends StatelessWidget {
  const MacroBars({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinGoal = 160,
    this.carbsGoal = 220,
    this.fatGoal = 70,
  });

  final int proteinG;
  final int carbsG;
  final int fatG;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroBar(
            label: 'Protein',
            value: proteinG,
            goal: proteinGoal,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroBar(
            label: 'Carbs',
            value: carbsG,
            goal: carbsGoal,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroBar(
            label: 'Fat',
            value: fatG,
            goal: fatGoal,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${value}g',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => LinearProgressIndicator(
              value: t,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
