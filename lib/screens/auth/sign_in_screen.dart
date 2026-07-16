import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _email = TextEditingController(text: 'alex@bodyx.app');
  final _password = TextEditingController(text: '••••••••');
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.read<AppState>().signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Welcome back',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Stay consistent',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 36),
              PrimaryTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 14),
              PrimaryTextField(
                label: 'Password',
                controller: _password,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Sign in',
                  light: true,
                  onPressed: _submit,
                  loading: _loading),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SocialAuthButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      light: true,
                      onTap: () => context.read<AppState>().signIn(
                          'alex@gmail.com', 'google-oauth'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SocialAuthButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
                      light: true,
                      onTap: () => context.read<AppState>().signIn(
                          'alex@icloud.com', 'apple-oauth'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Wrap(
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().goToSignUp(),
                      child: const Text('Sign up',
                          style: TextStyle(
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
