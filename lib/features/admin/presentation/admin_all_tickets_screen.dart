import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../tickets/presentation/widgets/ticket_card.dart';

class AdminAllTicketsScreen extends ConsumerStatefulWidget {
  const AdminAllTicketsScreen({super.key});

  @override
  ConsumerState<AdminAllTicketsScreen> createState() => _AdminAllTicketsScreenState();
}

class _AdminAllTicketsScreenState extends ConsumerState<AdminAllTicketsScreen> {
  final _searchController = TextEditingController();
  final Set<int> _selectedTicketIds = {};
  bool _isSelectionMode = false;
  String _activeQuickFilter = 'all'; // all, needs_approval, unassigned, mine, urgent
  final Map<String, String> _customFilters = {};

  void _showFilterSheet() {
    final schema = ref.read(schemaProvider).value;
    final filterableFields = schema?.fields.where((f) => f.filterable).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() => _customFilters.clear());
                      setState(() => _customFilters.clear());
                      ref.invalidate(ticketsProvider);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filterableFields.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No custom filterable fields available.', style: TextStyle(color: AppTheme.textMuted)),
                )
              else
                ...filterableFields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText: 'Filter by ${field.label}...',
                      ),
                      controller: TextEditingController(text: _customFilters['custom[${field.name}]'] ?? ''),
                      onChanged: (val) {
                        if (val.trim().isEmpty) {
                          _customFilters.remove('custom[${field.name}]');
                        } else {
                          _customFilters['custom[${field.name}]'] = val.trim();
                        }
                      },
                    ),
                  );
                }),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {});
                  ref.invalidate(ticketsProvider);
                },
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkOperationsSheet() {
    if (_selectedTicketIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bulk Actions (${_selectedTicketIds.length} tickets)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFD4EDDA),
                child: Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF006D15), size: 20),
              ),
              title: const Text('Bulk Approve', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Approve all selected new tickets'),
              onTap: () async {
                Navigator.pop(ctx);
                await _executeBulkAction('approve');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3EEFA),
                child: Icon(Icons.badge_rounded, color: AppTheme.primaryTeal, size: 20),
              ),
              title: const Text('Bulk Assign Employee', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Assign selected tickets to a staff member'),
              onTap: () {
                Navigator.pop(ctx);
                _showBulkAssignAgentSheet();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3CD),
                child: Icon(Icons.move_to_inbox_rounded, color: Color(0xFF7A5601), size: 20),
              ),
              title: const Text('Bulk Move Stage', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Move selected tickets to a workflow stage'),
              onTap: () {
                Navigator.pop(ctx);
                _showBulkChangeStageSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAssignAgentSheet() {
    final agentsAsync = ref.read(agentsProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => agentsAsync.when(
        data: (agents) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Assign Employee to Tickets',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.person_off_rounded, color: AppTheme.textMuted),
              ),
              title: const Text('Unassigned (Triage)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Return tickets to unassigned triage pool'),
              onTap: () async {
                Navigator.pop(ctx);
                await _executeBulkAction('assign', params: {'assignee_id': null});
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
                    '$count active',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _executeBulkAction('assign', params: {'assignee_id': agent['id']});
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
            child: Text(err is Failure ? err.userFriendlyMessage : 'Unable to load employees.'),
          ),
        ),
      ),
    );
  }

  void _showBulkChangeStageSheet() {
    final stagesAsync = ref.read(stagesProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => stagesAsync.when(
        data: (stages) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Move Selected Tickets to Stage', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...stages.map((stage) {
              final status = AppTheme.getStatusToken(stage.name, isClosed: stage.isClosed, sequence: stage.sequence);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: status.container,
                  child: Text(
                    '${stage.sequence}',
                    style: TextStyle(color: status.foreground, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _executeBulkAction('stage', params: {'stage_id': stage.id});
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
            child: Text(err is Failure ? err.userFriendlyMessage : 'Unable to load stages.'),
          ),
        ),
      ),
    );
  }

  Future<void> _executeBulkAction(String action, {Map<String, dynamic>? params}) async {
    final repo = ref.read(ticketRepositoryProvider);
    final count = _selectedTicketIds.length;
    try {
      final res = await repo.bulkUpdateTickets(
        action: action,
        ticketIds: _selectedTicketIds.toList(),
        params: params,
      );
      final results = (res['results'] as List?) ?? [];
      final successes = results.where((r) => r['ok'] == true).length;

      if (mounted) {
        AppDialogs.showSuccessSnackbar(
          context,
          'Bulk operation completed: $successes of $count tickets updated.',
        );
      }
      setState(() {
        _selectedTicketIds.clear();
        _isSelectionMode = false;
      });
      ref.invalidate(ticketsProvider);
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, title: 'Bulk Operation Failed', error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        title: _isSelectionMode
            ? Text('${_selectedTicketIds.length} Selected', style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('All Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedTicketIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: 'Select Tickets',
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter',
              onPressed: _showFilterSheet,
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                final allTickets = ticketsAsync.value ?? [];
                setState(() {
                  if (_selectedTicketIds.length == allTickets.length) {
                    _selectedTicketIds.clear();
                  } else {
                    _selectedTicketIds.addAll(allTickets.take(50).map((t) => t.id));
                  }
                });
              },
              child: const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedTicketIds.isNotEmpty
          ? Material(
              elevation: 8,
              color: AppTheme.surfaceCard,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${_selectedTicketIds.length} tickets selected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _showBulkOperationsSheet,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          const OfflineBanner(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by #, subject, or customer...',
                hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                fillColor: AppTheme.surfaceCard,
              ),
              onChanged: (v) {
                final current = ref.read(ticketFilterProvider);
                ref.read(ticketFilterProvider.notifier).state = current.copyWith(query: v);
              },
            ),
          ),

          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildQuickChip('all', 'All'),
                _buildQuickChip('needs_approval', 'Needs Approval'),
                _buildQuickChip('unassigned', 'Unassigned'),
                _buildQuickChip('mine', 'Assigned to Me'),
                _buildQuickChip('urgent', 'Urgent'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Tickets List
          Expanded(
            child: ticketsAsync.when(
              data: (allTickets) {
                // Apply quick filter locally for responsive admin UX
                final filtered = allTickets.where((t) {
                  if (_activeQuickFilter == 'needs_approval') {
                    return t.stage.name == 'New';
                  } else if (_activeQuickFilter == 'unassigned') {
                    return t.assignee == null;
                  } else if (_activeQuickFilter == 'mine') {
                    return t.assignee != null && (
                      (user?.employeeId != null && t.assignee!.id == user!.employeeId) ||
                      t.assignee!.id == user?.id ||
                      (t.assignee!.email != null && user?.email != null && t.assignee!.email!.toLowerCase() == user!.email.toLowerCase())
                    );
                  } else if (_activeQuickFilter == 'urgent') {
                    return t.priority >= 3;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No tickets match current filters.', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryTeal,
                  onRefresh: () async => ref.refresh(ticketsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 84),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final isSelected = _selectedTicketIds.contains(t.id);

                      return TicketCard(
                        ticket: t,
                        isSelectionMode: _isSelectionMode,
                        isSelected: isSelected,
                        onSelectChanged: (val) {
                          setState(() {
                            if (val == true) {
                              if (_selectedTicketIds.length < 50) _selectedTicketIds.add(t.id);
                            } else {
                              _selectedTicketIds.remove(t.id);
                            }
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedTicketIds.add(t.id);
                          });
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedTicketIds.remove(t.id);
                              } else if (_selectedTicketIds.length < 50) {
                                _selectedTicketIds.add(t.id);
                              }
                            });
                          } else {
                            context.push('/tickets/${t.id}');
                          }
                        },
                      );
                    },
                  ),
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
                      const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        err is Failure ? err.userFriendlyMessage : 'Unable to load tickets.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
                        onPressed: () => ref.refresh(ticketsProvider),
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

  Widget _buildQuickChip(String value, String label) {
    final isSelected = _activeQuickFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppTheme.surfaceCard,
        selectedColor: AppTheme.primaryTeal,
        side: BorderSide(color: isSelected ? AppTheme.primaryTeal : AppTheme.hairlineBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        onSelected: (_) {
          setState(() {
            _activeQuickFilter = value;
          });
        },
      ),
    );
  }
}
