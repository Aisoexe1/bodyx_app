import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/support_assistant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/scale_tap.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'new_ticket_screen.dart';
import 'tickets_list_screen.dart';

class _ChatMessage {
  _ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

/// A local, honestly-scoped support chat — see [SupportAssistant] for why
/// this matches keywords instead of calling a real model.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      "Hi! I'm the BodyX assistant. Ask me about water, calories, "
      "workouts, weight tracking, sleep, or syncing a wearable.",
      false,
    ),
  ];
  bool _typing = false;

  static const _suggestions = [
    'How do I log a meal?',
    'How is my TDEE calculated?',
    'Sync a wearable',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(_ChatMessage(trimmed, true));
      _controller.clear();
      _typing = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(_ChatMessage(SupportAssistant.reply(trimmed), false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          LinearGradient(colors: AppColors.primaryGradient),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.contactSupportTitle,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text(
                            AppLocalizations.of(context)!.contactSupportPoweredBy(
                                SupportAssistant.modelName),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!
                        .contactSupportMyTicketsTooltip,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TicketsListScreen()),
                    ),
                    icon: const Icon(Icons.confirmation_number_outlined,
                        size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 12),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) return const _TypingBubble();
                  return _MessageBubble(message: _messages[i]);
                },
              ),
            ),
            if (_messages.length <= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map((s) => ScaleTap(
                            onTap: () => _send(s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewTicketScreen()),
                ),
                child: Text(
                  AppLocalizations.of(context)!.contactSupportOpenTicketLink,
                  style: const TextStyle(
                      color: AppColors.primaryBright, fontSize: 12.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.contactSupportAskHint,
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleTap(
                    onTap: () => _send(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            LinearGradient(colors: AppColors.primaryGradient),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: fromUser
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: fromUser ? null : AppColors.card,
          border: fromUser ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(fromUser ? AppRadius.md : 4),
            bottomRight: Radius.circular(fromUser ? 4 : AppRadius.md),
          ),
        ),
        child: Text(message.text,
            style: TextStyle(
                color: fromUser ? Colors.white : AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2) % 1.0;
            final opacity = (0.3 + 0.7 * (0.5 + 0.5 * sin(t * 2 * pi)))
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
