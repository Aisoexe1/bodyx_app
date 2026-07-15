import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.success:
        return AppColors.success;
      case AlertSeverity.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const Expanded(
                      child: Text('Alerts',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (state.unreadAlertCount > 0)
                      TextButton(
                        onPressed: () =>
                            context.read<AppState>().markAllAlertsRead(),
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.unreadAlertCount} unread notifications',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ...List.generate(state.alerts.length, (i) {
                  final alert = state.alerts[i];
                  final color = _severityColor(alert.severity);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScaleTap(
                      onTap: () => context.read<AppState>().markAlertRead(i),
                      child: GlowCard(
                        borderColor: alert.read ? null : color,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlowIconBadge(icon: alert.icon, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(alert.title,
                                            style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.5)),
                                      ),
                                      Text(alert.time,
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(alert.subtitle,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                          height: 1.35)),
                                ],
                              ),
                            ),
                            if (!alert.read) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
