import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/brand_mark.dart';
import '../../widgets/common/inputs_buttons.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<AppState>().submitUsername(_controller.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.read<AppState>().goToSignUp(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Spacer(),
              const Center(child: BrandMark(size: 68)),
              const SizedBox(height: 10),
              const Center(
                child: Text('BodyX app',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 36),
              const Text('Choose a username',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                "This won't be visible to others",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              PrimaryTextField(
                label: 'Username',
                controller: _controller,
                prefixIcon: Icons.alternate_email_rounded,
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Confirm',
                light: true,
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
