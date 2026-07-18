import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class BottomNavItem {
  const BottomNavItem(this.icon, this.activeIcon);
  final IconData icon;
  final IconData activeIcon;
}

const List<BottomNavItem> kBottomNavItems = [
  BottomNavItem(Icons.home_outlined, Icons.home_rounded),
  BottomNavItem(Icons.show_chart_rounded, Icons.show_chart_rounded),
  BottomNavItem(Icons.grid_view_outlined, Icons.grid_view_rounded),
  BottomNavItem(Icons.notifications_outlined, Icons.notifications_rounded),
  BottomNavItem(Icons.person_outline_rounded, Icons.person_rounded),
];

/// Labels live here (index-matched to [kBottomNavItems]) rather than on the
/// const items themselves, since a localized string needs a BuildContext
/// that a top-level const list can't have.
String _navLabel(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.navHome;
    case 1:
      return l10n.navProgress;
    case 2:
      return l10n.navPlan;
    case 3:
      return l10n.navAlerts;
    default:
      return l10n.navProfile;
  }
}

/// Floating, glassy bottom navigation bar with an animated pill indicator
/// that slides beneath the active tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeIndex,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? badgeIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(kBottomNavItems.length, (i) {
          final item = kBottomNavItems[i];
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (i != currentIndex) HapticFeedback.selectionClick();
                onTap(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          color: active
                              ? AppColors.primaryBright
                              : AppColors.textMuted,
                          size: 22,
                        ),
                        if (badgeIndex == i)
                          Positioned(
                            top: -2,
                            right: -4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? AppColors.primaryBright
                            : AppColors.textMuted,
                      ),
                      child: Text(_navLabel(l10n, i)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
