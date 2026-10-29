import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/offline_banner.dart';
import '../domain/ticket.dart';

final ticketDetailProvider = FutureProvider.autoDispose.family<Ticket, int>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicket(ticketId);
});

final ticketMessagesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getMessages(ticketId);
});

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _isInternal = false;
  bool _isPosting = false;

  Future<void> _handlePostMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final repo = ref.read(ticketRepositoryProvider);
      await repo.postMessage(widget.ticketId, text, internal: _isInternal);
      _messageController.clear();
      ref.invalidate(ticketMessagesProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, title: 'Message Delivery Failed', error: e);
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showReopenDialog() {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reopen Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Please provide a brief explanation of why this issue requires further assistance:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Reopening *',
                hintText: 'Describe what remains unresolved...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                final repo = ref.read(ticketRepositoryProvider);
                Navigator.of(ctx).pop();
                try {
                  await repo.reopenTicket(widget.ticketId, reason);
                  if (mounted) {
                    ref.invalidate(ticketDetailProvider(widget.ticketId));
                    ref.invalidate(ticketMessagesProvider(widget.ticketId));
                    ref.invalidate(ticketsProvider);
                    AppDialogs.showSuccessSnackbar(context, 'Ticket has been reopened.');
                  }
                } catch (e) {
                  if (mounted) {
                    AppDialogs.showErrorDialog(context, title: 'Reopen Failed', error: e);
                  }
                }
              },
              child: const Text('Confirm Reopen', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 5;
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate Support Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'How satisfied are you with the resolution of this issue?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 38,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comments (Optional)', hintText: 'Share your feedback...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final repo = ref.read(ticketRepositoryProvider);
                    Navigator.of(ctx).pop();
                    try {
                      await repo.submitRating(widget.ticketId, rating, commentController.text.trim());
                      if (mounted) {
                        AppDialogs.showSuccessSnackbar(context, 'Thank you for your rating!');
                      }
                    } catch (e) {
                      if (mounted) {
                        AppDialogs.showErrorDialog(context, title: 'Rating Failed', error: e);
                      }
                    }
                  },
                  child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveSheet() {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Approve Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('The ticket will transition into the support workflow.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Comment to Customer (Optional)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final repo = ref.read(ticketRepositoryProvider);
                Navigator.of(ctx).pop();
                try {
                  await repo.approveTicket(widget.ticketId, comment: commentController.text.trim());
                  if (mounted) {
                    ref.invalidate(ticketDetailProvider(widget.ticketId));
                    ref.invalidate(ticketsProvider);
                    AppDialogs.showSuccessSnackbar(context, 'Ticket approved successfully.');
                  }
                } catch (e) {
                  if (mounted) {
                    AppDialogs.showErrorDialog(context, title: 'Approval Failed', error: e);
                  }
                }
              },
              child: const Text('Approve Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectSheet() {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reject Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB02A37))),
            const SizedBox(height: 8),
            const Text('A clear explanation is required and will be sent to the customer:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Rejection Reason *', hintText: 'Explain why this ticket was rejected...'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB02A37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                final repo = ref.read(ticketRepositoryProvider);
                Navigator.of(ctx).pop();
                try {
                  await repo.rejectTicket(widget.ticketId, reason);
                  if (mounted) {
                    ref.invalidate(ticketDetailProvider(widget.ticketId));
                    ref.invalidate(ticketsProvider);
                    AppDialogs.showSuccessSnackbar(context, 'Ticket has been rejected.');
                  }
                } catch (e) {
                  if (mounted) {
                    AppDialogs.showErrorDialog(context, title: 'Rejection Failed', error: e);
                  }
                }
              },
              child: const Text('Confirm Rejection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignAgentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Consumer(
        builder: (_, ref, _) {
          final agentsAsync = ref.watch(agentsProvider);
          return agentsAsync.when(
            data: (agents) => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Assign Employee',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person_off_rounded, color: AppTheme.textMuted),
                  ),
                  title: const Text('Unassigned (Triage Pool)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Return ticket to unassigned triage pool'),
                  onTap: () async {
                    final repo = this.ref.read(ticketRepositoryProvider);
                    Navigator.pop(ctx);
                    try {
                      await repo.assignTicket(widget.ticketId, null);
                      if (mounted) {
                        this.ref.invalidate(ticketDetailProvider(widget.ticketId));
                        this.ref.invalidate(ticketsProvider);
                        AppDialogs.showSuccessSnackbar(context, 'Ticket moved to unassigned triage queue.');
                      }
                    } catch (e) {
                      if (mounted) {
                        AppDialogs.showErrorDialog(context, title: 'Assignment Failed', error: e);
                      }
                    }
                  },
                ),
                const Divider(),
                ...agents.map((agent) {
                  final name = agent['name'] as String? ?? 'Employee';
                  final jobTitle = agent['job_title'] as String? ?? '';
                  final dept = agent['department'] as String? ?? '';
                  final count = agent['open_tickets_count'] ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      [jobTitle, dept].where((s) => s.isNotEmpty).join(' • '),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count open',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                    ),
                    onTap: () async {
                      final repo = this.ref.read(ticketRepositoryProvider);
                      Navigator.pop(ctx);
                      try {
                        await repo.assignTicket(widget.ticketId, agent['id']);
                        if (mounted) {
                          this.ref.invalidate(ticketDetailProvider(widget.ticketId));
                          this.ref.invalidate(ticketsProvider);
                          AppDialogs.showSuccessSnackbar(context, 'Ticket assigned to $name ($jobTitle)');
                        }
                      } catch (e) {
                        if (mounted) {
                          AppDialogs.showErrorDialog(context, title: 'Assignment Failed', error: e);
                        }
                      }
                    },
                  );
                }),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(err is Failure ? err.userFriendlyMessage : 'Unable to load employee list.'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangeStageSheet(List<TicketStage> stages) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text('Move Ticket to Stage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ...stages.map((s) {
            final status = AppTheme.getStatusToken(s.name, isClosed: s.isClosed, sequence: s.sequence);
            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: status.container,
                child: Text(
                  s.sequence.toString(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status.foreground),
                ),
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final repo = ref.read(ticketRepositoryProvider);
                Navigator.of(ctx).pop();
                try {
                  await repo.changeStage(widget.ticketId, s.id);
                  if (mounted) {
                    ref.invalidate(ticketDetailProvider(widget.ticketId));
                    ref.invalidate(ticketsProvider);
                    AppDialogs.showSuccessSnackbar(context, 'Ticket moved to stage: ${s.name}');
                  }
                } catch (e) {
                  if (mounted) {
                    AppDialogs.showErrorDialog(context, title: 'Stage Change Failed', error: e);
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));
    final stagesAsync = ref.watch(stagesProvider);
    final user = ref.watch(authNotifierProvider).value;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        title: Text(ticketAsync.value?.number ?? 'Ticket Detail', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ticketAsync.when(
              data: (ticket) {
                final isClosed = ticket.stage.isClosed;
                final status = AppTheme.getStatusToken(ticket.stage.name, isClosed: ticket.stage.isClosed, sequence: ticket.stage.sequence);
                final assignee = ticket.assignee;
                final customer = ticket.customer;

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.primaryTeal,
                        onRefresh: () async {
                          ref.invalidate(ticketDetailProvider(widget.ticketId));
                          ref.invalidate(ticketMessagesProvider(widget.ticketId));
                        },
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: [
                            // Header Card
                            Card(
                              color: AppTheme.surfaceCard,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.hairlineBorder),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surfaceContainer,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                ticket.number,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                                              ),
                                            ),
                                            if (ticket.priority > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: ticket.priority >= 3
                                                      ? const Color(0xFFFEE2E2)
                                                      : ticket.priority >= 2
                                                          ? const Color(0xFFFEF3C7)
                                                          : const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: ticket.priority >= 3
                                                        ? const Color(0xFFFECACA)
                                                        : ticket.priority >= 2
                                                            ? const Color(0xFFFDE68A)
                                                            : const Color(0xFFBAE6FD),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ...List.generate(
                                                      ticket.priority,
                                                      (_) => Icon(
                                                        Icons.star_rounded,
                                                        size: 14,
                                                        color: ticket.priority >= 3
                                                            ? const Color(0xFFDC2626)
                                                            : ticket.priority >= 2
                                                                ? const Color(0xFFD97706)
                                                                : const Color(0xFF0284C7),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      ticket.priority == 3
                                                          ? 'Urgent'
                                                          : ticket.priority == 2
                                                              ? 'High'
                                                              : 'Medium',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: ticket.priority >= 3
                                                            ? const Color(0xFF991B1B)
                                                            : ticket.priority >= 2
                                                                ? const Color(0xFF92400E)
                                                                : const Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status.container,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: status.border),
                                          ),
                                          child: Text(
                                            ticket.stage.name,
                                            style: TextStyle(
                                              color: status.foreground,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      ticket.subject,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                    if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        Formatters.cleanHtml(ticket.description!),
                                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.35),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Assignee & Customer Details Card
                            Card(
                              color: AppTheme.surfaceCard,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.hairlineBorder),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Assignee Row
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: assignee != null
                                              ? AppTheme.primaryTeal.withValues(alpha: 0.18)
                                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                          child: assignee != null
                                              ? Text(
                                                  assignee.name.isNotEmpty ? assignee.name[0].toUpperCase() : 'E',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                                )
                                              : const Icon(Icons.person_search_rounded, size: 20, color: Color(0xFFB45309)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      assignee != null ? assignee.name : 'Unassigned',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: assignee != null ? AppTheme.textPrimary : const Color(0xFFB45309),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (assignee != null) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Employee',
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                assignee != null
                                                    ? [assignee.jobTitle, assignee.department].where((s) => s.isNotEmpty).join(' • ')
                                                    : 'No employee assigned yet',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (ticket.can('assign') || isAdmin)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.primaryTeal,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                            label: Text(assignee != null ? 'Reassign' : 'Assign'),
                                            onPressed: _showAssignAgentSheet,
                                          ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Customer Row
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme.secondaryAubergine.withValues(alpha: 0.15),
                                          child: Text(
                                            customer != null && customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryAubergine),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer?.name ?? 'Customer',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                              ),
                                              Text(
                                                [customer?.email, customer?.phone].where((s) => s != null && s.isNotEmpty).join(' • '),
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dynamic Stage Stepper
                            stagesAsync.when(
                              data: (stages) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: stages.map((s) {
                                        final isRejectedTicket = ticket.stage.name == 'Rejected';
                                        final isDoneTicket = ticket.stage.name == 'Done';
                                        final isCurrent = s.name == ticket.stage.name;

                                        bool isPassed = false;
                                        if (isRejectedTicket) {
                                          isPassed = s.name == 'New';
                                        } else if (isDoneTicket) {
                                          isPassed = s.name != 'Rejected' && s.sequence <= ticket.stage.sequence;
                                        } else {
                                          isPassed = s.name != 'Rejected' && s.sequence < ticket.stage.sequence;
                                        }

                                        Color badgeBg;
                                        Color badgeTextColor;

                                        if (isCurrent) {
                                          if (s.name == 'Rejected') {
                                            badgeBg = const Color(0xFFDC3545);
                                            badgeTextColor = Colors.white;
                                          } else if (s.name == 'Done') {
                                            badgeBg = const Color(0xFF198754);
                                            badgeTextColor = Colors.white;
                                          } else {
                                            badgeBg = AppTheme.primaryTeal;
                                            badgeTextColor = Colors.white;
                                          }
                                        } else if (isPassed) {
                                          badgeBg = const Color(0xFFD4EDDA);
                                          badgeTextColor = const Color(0xFF0F5132);
                                        } else {
                                          badgeBg = AppTheme.surfaceContainer;
                                          badgeTextColor = AppTheme.textSecondary;
                                        }

                                        return Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                s.name,
                                                style: TextStyle(
                                                  color: badgeTextColor,
                                                  fontSize: 11,
                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (s != stages.last) const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            // Rejection Reason Card if Rejected
                            if (ticket.stage.name == 'Rejected' && (ticket.rejectionReason?.isNotEmpty ?? false))
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8D7DA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF1AEB5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.cancel_rounded, size: 18, color: Color(0xFFB02A37)),
                                        SizedBox(width: 6),
                                        Text('Rejection Reason', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB02A37))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(ticket.rejectionReason!, style: const TextStyle(color: Color(0xFFB02A37), fontSize: 13)),
                                  ],
                                ),
                              ),

                            // Contextual Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (ticket.can('confirm'))
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F5132),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Confirm Resolved'),
                                      onPressed: () async {
                                        try {
                                          final repo = ref.read(ticketRepositoryProvider);
                                          await repo.confirmResolution(ticket.id);
                                          ref.invalidate(ticketDetailProvider(widget.ticketId));
                                          ref.invalidate(ticketsProvider);
                                          if (context.mounted) {
                                            AppDialogs.showSuccessSnackbar(context, 'Ticket marked as resolved.');
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            AppDialogs.showErrorDialog(context, title: 'Action Failed', error: e);
                                          }
                                        }
                                      },
                                    ),
                                  if (ticket.can('reopen'))
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.replay),
                                      label: const Text('Reopen Ticket'),
                                      onPressed: _showReopenDialog,
                                    ),
                                  if (ticket.can('rate'))
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF59E0B),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.star_outline),
                                      label: const Text('Rate Support'),
                                      onPressed: _showRatingDialog,
                                    ),
                                  if (ticket.can('approve'))
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F5132),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.thumb_up_alt_rounded),
                                      label: const Text('Approve Ticket'),
                                      onPressed: _showApproveSheet,
                                    ),
                                  if (ticket.can('reject'))
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFB02A37),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.thumb_down_alt_rounded),
                                      label: const Text('Reject Ticket'),
                                      onPressed: _showRejectSheet,
                                    ),
                                  if (ticket.can('change_stage') && stagesAsync.value != null)
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.move_to_inbox_rounded),
                                      label: const Text('Change Stage'),
                                      onPressed: () => _showChangeStageSheet(stagesAsync.value!),
                                    ),
                                  if (ticket.can('assign'))
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.assignment_ind_rounded),
                                      label: Text(ticket.assignee != null ? 'Reassign Employee' : 'Assign Employee'),
                                      onPressed: _showAssignAgentSheet,
                                    ),
                                ],
                              ),
                            ),

                            // Custom Fields Details Card (No snake_case, No raw developer keys)
                            if (ticket.custom.isNotEmpty)
                              Card(
                                color: AppTheme.surfaceCard,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppTheme.hairlineBorder),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryTeal),
                                          SizedBox(width: 8),
                                          Text(
                                            'Custom Field Details',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ...ticket.custom.entries.map((entry) {
                                        final label = Formatters.humanizeFieldName(entry.key);
                                        final value = Formatters.formatCustomValue(entry.value);
                                        if (value.isEmpty) return const SizedBox.shrink();

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 140,
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                            const Text(
                              'Conversation & Updates',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),

                            // Messages List
                            messagesAsync.when(
                              data: (messages) {
                                final validMessages = messages.where((m) {
                                  final body = m['body'] as String? ?? '';
                                  return Formatters.cleanHtml(body).isNotEmpty;
                                }).toList();

                                if (validMessages.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No messages posted yet.',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: validMessages.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, idx) {
                                    final m = validMessages[idx];
                                    final isInternal = m['is_internal'] == true;
                                    final authorName = m['author']?['name'] ?? 'User';
                                    final jobTitle = m['author']?['job_title'] as String?;
                                    final timeStr = m['created_at'] != null ? Formatters.formatRelativeTime(DateTime.tryParse(m['created_at'])) : '';
                                    final cleanText = Formatters.cleanHtml(m['body'] as String? ?? '');

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isInternal ? const Color(0xFFFFFBEB) : AppTheme.surfaceCard,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isInternal ? const Color(0xFFFDE68A) : AppTheme.hairlineBorder,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        authorName,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (jobTitle != null && jobTitle.isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          '• $jobTitle',
                                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (timeStr.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Text(timeStr, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                              ],
                                              if (isInternal) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Internal Note',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cleanText,
                                            style: const TextStyle(fontSize: 13, height: 1.35, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                                ),
                              ),
                              error: (err, _) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  err is Failure ? err.userFriendlyMessage : 'Unable to load conversation.',
                                  style: const TextStyle(color: Color(0xFFB02A37)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reply Composer
                    if (ticket.can('reply') || isAdmin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Reply to Customer', style: TextStyle(fontSize: 12)),
                                        selected: !_isInternal,
                                        selectedColor: AppTheme.primaryTeal,
                                        labelStyle: TextStyle(
                                          color: !_isInternal ? Colors.white : AppTheme.textSecondary,
                                          fontWeight: !_isInternal ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        onSelected: (_) => setState(() => _isInternal = false),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Internal Note', style: TextStyle(fontSize: 12)),
                                        selected: _isInternal,
                                        selectedColor: const Color(0xFFB45309),
                                        labelStyle: TextStyle(
                                          color: _isInternal ? Colors.white : AppTheme.textSecondary,
                                          fontWeight: _isInternal ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        onSelected: (_) => setState(() => _isInternal = true),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: _isInternal ? 'Write an internal note...' : 'Reply to customer...',
                                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        fillColor: AppTheme.surfaceCanvas,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: _isInternal ? const Color(0xFFB45309) : AppTheme.primaryTeal,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _isPosting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send),
                                    onPressed: _isPosting ? null : _handlePostMessage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (isClosed)
                      Container(
                        padding: const EdgeInsets.all(14),
                        color: AppTheme.surfaceContainerLow,
                        width: double.infinity,
                        child: const Text(
                          'This ticket is closed. Tap "Reopen Ticket" above to continue the conversation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        err is Failure ? err.userFriendlyMessage : 'Unable to load ticket details.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => ref.refresh(ticketDetailProvider(widget.ticketId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
