import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/push_notification_service.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _notifyNewTicket = true;
  bool _notifyCustomerReply = true;
  bool _notifyReopenedConfirmed = true;
  bool _urgentOnlyFilter = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings & Workload', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Admin User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Helpdesk Administrator',
                            style: TextStyle(color: Colors.purple.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notification Preferences
          const Text('Push Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.add_alert_outlined),
                  title: const Text('New Ticket Raised'),
                  subtitle: const Text('Notify when a customer submits a new ticket'),
                  value: _notifyNewTicket,
                  onChanged: (val) => setState(() => _notifyNewTicket = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Customer Replied'),
                  subtitle: const Text('Notify on customer replies to tickets'),
                  value: _notifyCustomerReply,
                  onChanged: (val) => setState(() => _notifyCustomerReply = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.published_with_changes_outlined),
                  title: const Text('Ticket Reopened or Confirmed'),
                  subtitle: const Text('Notify when a customer reopens or confirms resolution'),
                  value: _notifyReopenedConfirmed,
                  onChanged: (val) => setState(() => _notifyReopenedConfirmed = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  title: const Text('Urgent Priority Only'),
                  subtitle: const Text('Only send push alerts for high & urgent tickets'),
                  value: _urgentOnlyFilter,
                  onChanged: (val) => setState(() => _urgentOnlyFilter = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Localization & Appearance
          const Text('Localization & System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'বাংলা', child: Text('বাংলা (Bengali)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Odoo Endpoint'),
                  subtitle: Text(ApiClient.defaultBaseUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_other),
                  title: const Text('Push Notification Service'),
                  subtitle: Text(PushNotificationService.instance.isConfigured
                      ? 'Connected (Demo FCM Active)'
                      : 'Simulated Mode (Config Flag Disabled)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
