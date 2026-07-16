import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _socialSignIn(String email, String provider) {
    context.read<AppState>().signIn(email, provider).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(e))));
      }
    });
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
              const Text('Create your account',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Join us and start your journey',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 32),
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
              const SizedBox(height: 14),
              PrimaryTextField(
                label: 'Repeat the password',
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Next',
                light: true,
                onPressed: () => context
                    .read<AppState>()
                    .submitSignUp(_email.text, _password.text),
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 20),
              SocialAuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                light: true,
                onTap: () => _socialSignIn('alex@gmail.com', 'google-oauth'),
              ),
              const SizedBox(height: 12),
              SocialAuthButton(
                label: 'Continue with Apple',
                icon: Icons.apple_rounded,
                light: true,
                onTap: () => _socialSignIn('alex@icloud.com', 'apple-oauth'),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.read<AppState>().goToSignIn(),
                      child: const Text('Sign in',
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
