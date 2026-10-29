import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HELPDESK COMMAND HUB',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppTheme.secondaryAubergine),
            ),
            Text(
              'Executive Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: AppTheme.textSecondary),
            tooltip: 'Customers Directory',
            onPressed: () => context.push('/admin/customers'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            tooltip: 'Settings',
            onPressed: () => context.push('/admin/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryTeal,
              onRefresh: () async => ref.refresh(dashboardMetricsProvider),
              child: metricsAsync.when(
                data: (metrics) {
                  final awaiting = metrics['awaiting_approval'] ?? 0;
                  final unassigned = metrics['unassigned'] ?? 0;
                  final urgent = metrics['urgent'] ?? 0;
                  final mine = metrics['mine'] ?? 0;
                  final stages = (metrics['stages'] as List?) ?? [];

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Greeting & SLA Pulse Banner (from Stitch a1)
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'OPERATIONS DESK',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
                                      ),
                                      Text(
                                        'Welcome, ${user?.name ?? "Helpdesk Lead"}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.analytics_outlined, size: 20, color: AppTheme.primaryTeal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryTeal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        '100% Core API Health • Odoo Backend Active',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    const Icon(Icons.trending_up, size: 16, color: AppTheme.primaryTeal),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2x2 Top KPI Grid (from Stitch a1)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStitchKpiCard(
                              context,
                              title: 'Awaiting Approval',
                              count: awaiting.toString(),
                              icon: Icons.verified_user_outlined,
                              iconColor: AppTheme.secondaryAubergine,
                              tagLabel: 'Needs Review',
                              tagBg: AppTheme.statusApproved.container,
                              tagTextColor: AppTheme.statusApproved.foreground,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStitchKpiCard(
                              context,
                              title: 'Unassigned',
                              count: unassigned.toString(),
                              icon: Icons.person_off_outlined,
                              iconColor: const Color(0xFF00617D),
                              tagLabel: 'Triage',
                              tagBg: AppTheme.statusTracking.container,
                              tagTextColor: AppTheme.statusTracking.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStitchKpiCard(
                              context,
                              title: 'Urgent Priority',
                              count: urgent.toString(),
                              icon: Icons.warning_amber_rounded,
                              iconColor: const Color(0xFFDC3545),
                              tagLabel: 'Immediate',
                              tagBg: AppTheme.statusRejected.container,
                              tagTextColor: AppTheme.statusRejected.foreground,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStitchKpiCard(
                              context,
                              title: 'Assigned to Me',
                              count: mine.toString(),
                              icon: Icons.assignment_ind_outlined,
                              iconColor: AppTheme.primaryTeal,
                              tagLabel: 'Active Work',
                              tagBg: AppTheme.statusDone.container,
                              tagTextColor: AppTheme.statusDone.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stage Breakdown Section (from Stitch a1)
                      const Text(
                        'Workload by Stage',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: AppTheme.surfaceCard,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppTheme.hairlineBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: stages.map<Widget>((s) {
                              final name = s['name'] ?? '';
                              final count = s['count'] ?? 0;
                              final status = AppTheme.getStatusToken(name);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: status.foreground,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status.container,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: status.border),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: status.foreground),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Navigation Actions
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Manage All Tickets & Queues', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/admin/tickets'),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load operations metrics.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => ref.refresh(dashboardMetricsProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchKpiCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required String tagLabel,
    required Color tagBg,
    required Color tagTextColor,
  }) {
    return Card(
      color: AppTheme.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.hairlineBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/tickets'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.0),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tagLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
