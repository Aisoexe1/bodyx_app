import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Segmented heart-rate zone bar with a marker at the current %-of-max —
/// the same zones as [HealthInsights.hrZoneFor], drawn instead of read as
/// numbers so the current intensity reads at a glance.
class HrZoneBar extends StatelessWidget {
  const HrZoneBar({super.key, required this.fraction, required this.zoneLabel});

  /// 0..~1.3 fraction of estimated max HR.
  final double fraction;
  final String zoneLabel;

  static const _segments = [
    (width: 0.50, color: AppColors.textMuted, label: 'Отдых'),
    (width: 0.10, color: AppColors.info, label: 'Разминка'),
    (width: 0.10, color: AppColors.primary, label: 'Жиросжиг.'),
    (width: 0.15, color: AppColors.success, label: 'Рост мышц'),
    (width: 0.15, color: AppColors.warningDeep, label: 'Максимум'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final markerX = (fraction.clamp(0.0, 1.0)) * constraints.maxWidth;
            return SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: _segments
                          .map((s) => Expanded(
                                flex: (s.width * 1000).round(),
                                child: Container(height: 28, color: s.color),
                              ))
                          .toList(),
                    ),
                  ),
                  Positioned(
                    left: (markerX - 1.5).clamp(0.0, constraints.maxWidth - 3),
                    top: -4,
                    child: Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: _segments
              .map((s) => Expanded(
                    flex: (s.width * 1000).round(),
                    child: Text(
                      s.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textMuted),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(zoneLabel,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ],
    );
  }
}
