import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Sub-Header Pill (from Stitch s6)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.hairlineBorder),
                ),
                child: const Text('Odoo v19.0 Enterprise Connected', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryTeal),
                label: const Text('Edit', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),

          // User Profile Card
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
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryTeal,
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Alex Morgan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user?.isAdmin == true ? AppTheme.statusApproved.container : AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: user?.isAdmin == true ? AppTheme.statusApproved.border : AppTheme.hairlineBorder),
                              ),
                              child: Text(
                                user?.isAdmin == true ? 'Helpdesk Administrator' : 'Enterprise Customer Portal',
                                style: TextStyle(
                                  color: user?.isAdmin == true ? AppTheme.statusApproved.foreground : AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Strip
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Status', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            SizedBox(height: 2),
                            Text('Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('SLA Tier', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            SizedBox(height: 2),
                            Text('Platinum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Satisfaction', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            SizedBox(height: 2),
                            Text('99.2%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006D15))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Section
          const Text('Account & Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surfaceCard,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.hairlineBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                  title: const Text('Notifications Inbox'),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1, color: AppTheme.hairlineBorder),
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.textSecondary),
                  title: const Text('Language'),
                  subtitle: const Text('English (Default)'),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppTheme.hairlineBorder),
                ListTile(
                  leading: const Icon(Icons.security_outlined, color: AppTheme.textSecondary),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                  onTap: () => context.push('/forgot-password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRejected.container,
              foregroundColor: AppTheme.statusRejected.foreground,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.statusRejected.border),
              ),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out of Account', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
