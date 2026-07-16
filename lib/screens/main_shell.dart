import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/nav/bottom_nav.dart';
import 'alerts/alerts_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'plan/plan_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_screen.dart';

/// Hosts the five primary tabs behind the floating bottom nav. Screens are
/// kept alive in an IndexedStack so scroll position / chart animations
/// aren't lost when switching tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedSwitcher(
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: state.navIndex,
        onTap: (i) => context.read<AppState>().selectNav(i),
        badgeIndex: state.unreadAlertCount > 0 ? 3 : null,
      ),
    );
  }
}
