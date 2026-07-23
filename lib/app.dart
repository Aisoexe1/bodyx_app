import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/auth/body_data_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/username_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// [MaterialScrollBehavior] excludes the mouse from [dragDevices] by
/// default (click-drag is reserved for text selection on web/desktop) —
/// which silently breaks click-and-drag scrolling, and with it the
/// Dashboard's pull-to-refresh, on a mouse-only Windows desktop build with
/// no touchscreen or trackpad. Adding it back is the standard fix.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class BodyXApp extends StatelessWidget {
  const BodyXApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: Builder(
        builder: (context) {
          final locale = context.select<AppState, Locale?>((s) => s.locale);
          return MaterialApp(
            title: 'BodyX',
            debugShowCheckedModeBanner: false,
            scrollBehavior: _AppScrollBehavior(),
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AuthGate(),
          );
        },
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
      case AuthStage.forgotPassword:
        child = const ForgotPasswordScreen();
        break;
      case AuthStage.resetPassword:
        child = const ResetPasswordScreen();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(stage), child: child),
    );
  }
}
