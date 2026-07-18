import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
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
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.alertsTitle,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (state.unreadAlertCount > 0)
                      TextButton(
                        onPressed: () =>
                            context.read<AppState>().markAllAlertsRead(),
                        child:
                            Text(AppLocalizations.of(context)!.alertsMarkAllRead),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.alertsUnreadCount(
                      state.unreadAlertCount.toString()),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                if (state.alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_off_rounded,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context)!.alertsEmptyTitle,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.alertsEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  )
                else
                  ...state.alerts.map((alert) {
                    final color = _severityColor(alert.severity);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ScaleTap(
                        onTap: () =>
                            context.read<AppState>().markAlertRead(alert.id),
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
                                    Text(alert.title,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5)),
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
