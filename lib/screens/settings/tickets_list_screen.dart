import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../network/api_client.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import 'new_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  late Future<List<SupportTicket>> _future = _load();

  Future<List<SupportTicket>> _load() =>
      context.read<AppState>().listSupportTickets();

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _openNewTicket() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewTicketScreen()),
    );
    if (mounted) _refresh();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Text(l10n.ticketsListTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    onPressed: _openNewTicket,
                    icon: const Icon(Icons.add_rounded,
                        color: AppColors.primaryBright),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SupportTicket>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBright),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(describeApiError(snapshot.error!),
                          style: const TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  final tickets = snapshot.data ?? const [];
                  if (tickets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(l10n.ticketsEmptyTitle,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(l10n.ticketsEmptyMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.5)),
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: l10n.ticketsNewButton,
                              onPressed: _openNewTicket,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 12),
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = tickets[i];
                        final closed = t.status == TicketStatus.closed;
                        return ScaleTap(
                          onTap: () => _openTicket(t),
                          child: GlowCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.subject,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                        closed
                                            ? l10n.ticketsStatusClosed
                                            : l10n.ticketsStatusOpen,
                                        style: TextStyle(
                                            color: closed
                                                ? AppColors.textMuted
                                                : AppColors.success,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
