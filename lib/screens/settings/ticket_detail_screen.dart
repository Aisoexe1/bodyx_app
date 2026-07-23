import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/scale_tap.dart';

/// A single ticket thread — the real, admin-answerable counterpart to the
/// local keyword chat in [ContactSupportScreen].
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final SupportTicket ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late SupportTicket _ticket = widget.ticket;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Polls for the admin's reply while the thread is open — there's no
    // push/websocket channel here, so this is the simplest way for a reply
    // to show up without the user backing out and re-opening the ticket.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final updated =
          await context.read<AppState>().getSupportTicket(_ticket.id);
      if (!mounted) return;
      if (updated.messages.length != _ticket.messages.length) {
        setState(() => _ticket = updated);
        _scrollToBottom();
      } else if (updated.status != _ticket.status) {
        setState(() => _ticket = updated);
      }
    } catch (_) {
      // Best-effort background refresh — a transient network hiccup here
      // shouldn't interrupt the user or show an error over their own typing.
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final updated =
          await context.read<AppState>().addSupportTicketMessage(_ticket.id, text);
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _controller.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    final l10n = AppLocalizations.of(context)!;
    final closed = _ticket.status == TicketStatus.closed;
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
                      onPressed: () => Navigator.pop(context, _ticket),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ticket.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text(
                              closed
                                  ? l10n.ticketsStatusClosed
                                  : l10n.ticketsStatusOpen,
                              style: TextStyle(
                                  color: closed
                                      ? AppColors.textMuted
                                      : AppColors.success,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
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
                  itemCount: _ticket.messages.length,
                  itemBuilder: (context, i) =>
                      _TicketMessageBubble(message: _ticket.messages[i]),
                ),
              ),
              if (closed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, 8),
                  child: Text(l10n.ticketDetailClosedBanner,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
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
                          hintText: l10n.ticketDetailReplyHint,
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleTap(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              LinearGradient(colors: AppColors.primaryGradient),
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_upward_rounded,
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

class _TicketMessageBubble extends StatelessWidget {
  const _TicketMessageBubble({required this.message});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.sender == TicketMessageSender.user;
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
