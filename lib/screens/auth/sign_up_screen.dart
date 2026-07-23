import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/password_strength.dart';
import '../../logic/social_auth.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/brand_mark.dart';
import '../../widgets/common/inputs_buttons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _showValidation = false;

  bool get _passwordValid => PasswordStrength.isValid(_password.text);
  bool get _confirmMatches =>
      _confirmPassword.text.isNotEmpty && _confirmPassword.text == _password.text;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
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

  void _submit() {
    setState(() => _showValidation = true);
    if (!_passwordValid || !_confirmMatches) return;
    context.read<AppState>().submitSignUp(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.read<AppState>().goToSignIn(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(height: 8),
              const Center(child: BrandMark(size: 72)),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.signUpTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.signUpSubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 32),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.signUpEmailLabel,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.signUpPasswordLabel,
                controller: _password,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
                onChanged: (_) => setState(() {}),
                errorText: _showValidation && !_passwordValid
                    ? PasswordStrength.hint
                    : null,
                helperText: _showValidation && !_passwordValid
                    ? null
                    : PasswordStrength.hint,
                helperColor: _passwordValid ? AppColors.success : null,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.signUpRepeatPasswordLabel,
                controller: _confirmPassword,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                onChanged: (_) => setState(() {}),
                errorText: _showValidation && !_confirmMatches
                    ? AppLocalizations.of(context)!.signUpPasswordMismatch
                    : null,
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: AppLocalizations.of(context)!.signUpNextButton,
                light: true,
                onPressed: _submit,
              ),
              // google_sign_in targets mobile/web and sign_in_with_apple has
              // no Windows support — hidden outside Android/iOS rather than
              // shown and silently failing every tap.
              if (SocialAuth.isSupported) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(AppLocalizations.of(context)!.signUpOrDivider,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 20),
                SocialAuthButton(
                  label: AppLocalizations.of(context)!.signUpContinueWithGoogle,
                  icon: Icons.g_mobiledata_rounded,
                  light: true,
                  onTap: _signInWithGoogle,
                ),
                const SizedBox(height: 12),
                SocialAuthButton(
                  label: AppLocalizations.of(context)!.signUpContinueWithApple,
                  icon: Icons.apple_rounded,
                  light: true,
                  onTap: _signInWithApple,
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  children: [
                    Text(AppLocalizations.of(context)!.signUpAlreadyHaveAccount,
                        style: const TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().goToSignIn(),
                      child: Text(AppLocalizations.of(context)!.signUpSignInLink,
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
