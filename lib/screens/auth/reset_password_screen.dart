import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/password_strength.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/inputs_buttons.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _showValidation = false;
  bool _loading = false;

  bool get _passwordValid => PasswordStrength.isValid(_password.text);
  bool get _confirmMatches =>
      _confirmPassword.text.isNotEmpty && _confirmPassword.text == _password.text;
  bool get _codeValid => _code.text.trim().length == 6;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showValidation = true);
    if (!_codeValid || !_passwordValid || !_confirmMatches) return;

    setState(() => _loading = true);
    try {
      await context
          .read<AppState>()
          .confirmPasswordReset(_code.text.trim(), _password.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppState>().pendingResetEmail;
    final devCode = context.watch<AppState>().devResetCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.read<AppState>().goToForgotPassword(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.resetPasswordEnterCode,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                email == null
                    ? AppLocalizations.of(context)!.resetPasswordCheckEmail
                    : AppLocalizations.of(context)!
                        .resetPasswordSentCode(email.toString()),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              if (devCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .resetPasswordDevMode(devCode.toString()),
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.resetPasswordCodeLabel,
                controller: _code,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.pin_outlined,
                onChanged: (_) => setState(() {}),
                errorText: _showValidation && !_codeValid
                    ? AppLocalizations.of(context)!.resetPasswordCodeError
                    : null,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.resetPasswordNewPasswordLabel,
                controller: _password,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
                onChanged: (_) => setState(() {}),
                errorText: _showValidation && !_passwordValid ? PasswordStrength.hint : null,
                helperText: _showValidation && !_passwordValid ? null : PasswordStrength.hint,
                helperColor: _passwordValid ? AppColors.success : null,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: AppLocalizations.of(context)!.resetPasswordRepeatPasswordLabel,
                controller: _confirmPassword,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                onChanged: (_) => setState(() {}),
                errorText: _showValidation && !_confirmMatches
                    ? AppLocalizations.of(context)!.resetPasswordMismatchError
                    : null,
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: AppLocalizations.of(context)!.resetPasswordButton,
                light: true,
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AppState>().goToSignIn(),
                  child: Text(AppLocalizations.of(context)!.resetPasswordBackToSignIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
