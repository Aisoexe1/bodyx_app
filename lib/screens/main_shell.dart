import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_background.dart';
import '../widgets/nav/bottom_nav.dart';
import 'alerts/alerts_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'plan/plan_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_screen.dart';

/// Hosts the five primary tabs behind the floating bottom nav. Screens are
/// kept alive in an IndexedStack so scroll position / chart animations
/// aren't lost when switching tabs.
///
/// The textured [AppBackground] lives here (not globally in app.dart's
/// MaterialApp.builder) because this widget is only ever swapped in place —
/// never pushed as a route. A transparent Scaffold on a *pushed* screen
/// leaves the previous route visible and repainting underneath it for the
/// whole transition (visible ghosting + jank), so every pushed screen keeps
/// a plain opaque background instead.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(state.navIndex),
              child: const [
                DashboardScreen(),
                ProgressScreen(),
                PlanScreen(),
                AlertsScreen(),
                ProfileScreen(),
              ][state.navIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: state.navIndex,
        onTap: (i) => context.read<AppState>().selectNav(i),
        badgeIndex: state.unreadAlertCount > 0 ? 3 : null,
      ),
    );
  }
}
