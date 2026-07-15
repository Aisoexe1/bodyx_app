import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/body_data_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/username_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class BodyXApp extends StatelessWidget {
  const BodyXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'BodyX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Swaps between splash / auth / onboarding / main-shell based on
/// [AppState.authStage], with a soft cross-fade between stages.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final stage = context.select<AppState, AuthStage>((s) => s.authStage);

    Widget child;
    switch (stage) {
      case AuthStage.splash:
        child = const SplashScreen();
        break;
      case AuthStage.signIn:
        child = const SignInScreen();
        break;
      case AuthStage.signUp:
        child = const SignUpScreen();
        break;
      case AuthStage.chooseUsername:
        child = const UsernameScreen();
        break;
      case AuthStage.bodyData:
        child = const BodyDataScreen();
        break;
      case AuthStage.done:
        child = const MainShell();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(stage), child: child),
    );
  }
}
