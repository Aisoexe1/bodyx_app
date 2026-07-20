import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/social_auth.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/inputs_buttons.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.signInFieldsRequired)));
      return;
    }
    setState(() => _loading = true);
    try {
      await context
          .read<AppState>()
          .signIn(_email.text, _password.text, rememberMe: _rememberMe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final idToken = await SocialAuth.signInWithGoogle();
      if (idToken == null || !mounted) return; // user cancelled
      await context.read<AppState>().signInWithGoogle(idToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final identityToken = await SocialAuth.signInWithApple();
      if (identityToken == null || !mounted) return; // user cancelled
      await context.read<AppState>().signInWithApple(identityToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.signInWelcomeBack,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.signInStayConsistent,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 36),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.signInEmailLabel,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.signInPasswordLabel,
                controller: _password,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.signInRememberMe,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: AppLocalizations.of(context)!.signInSignInButton,
                  light: true,
                  onPressed: _submit,
                  loading: _loading),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AppState>().goToForgotPassword(),
                  child: Text(AppLocalizations.of(context)!.signInForgotPassword),
                ),
              ),
              // google_sign_in targets mobile/web and sign_in_with_apple has
              // no Windows support — hidden outside Android/iOS rather than
              // shown and silently failing every tap.
              if (SocialAuth.isSupported) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                          AppLocalizations.of(context)!.signInOrContinueWith,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SocialAuthButton(
                        label: AppLocalizations.of(context)!.signInGoogleLabel,
                        icon: Icons.g_mobiledata_rounded,
                        light: true,
                        onTap: _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SocialAuthButton(
                        label: AppLocalizations.of(context)!.signInAppleLabel,
                        icon: Icons.apple_rounded,
                        light: true,
                        onTap: _signInWithApple,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: Wrap(
                  children: [
                    Text(AppLocalizations.of(context)!.signInNoAccount,
                        style: const TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().goToSignUp(),
                      child: Text(AppLocalizations.of(context)!.signInSignUp,
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
