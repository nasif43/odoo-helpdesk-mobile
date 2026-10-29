import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Ticket #104 Approved',
      'body': 'Marcus Vance (Operations Lead) accepted your ticket and assigned it to Senior Support.',
      'time': '10 mins ago',
      'unread': true,
      'ticket_id': 1,
      'type': 'stage',
    },
    {
      'id': 2,
      'title': 'New Reply on #108',
      'body': 'Agent Sarah Jenkins: "We have isolated the network gateway issue."',
      'time': '25 mins ago',
      'unread': true,
      'ticket_id': 2,
      'type': 'message',
    },
    {
      'id': 3,
      'title': 'Ticket #112 Moved to Solving',
      'body': 'Issue resolution applied. Please verify and confirm resolution.',
      'time': '1 hour ago',
      'unread': false,
      'ticket_id': 3,
      'type': 'stage',
    },
    {
      'id': 4,
      'title': 'Ticket #115 Closed',
      'body': 'Support issue marked Done. Tap to rate your service experience.',
      'time': 'Yesterday',
      'unread': false,
      'ticket_id': 4,
      'type': 'done',
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n['unread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['unread'] == true).length;
    final filtered = _notifications.where((n) {
      if (_activeFilter == 'unread') return n['unread'] == true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
      ),
      body: Column(
        children: [
          // Sub-Header Bar (from Stitch s5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Inbox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all, size: 16, color: AppTheme.primaryTeal),
                  label: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${_notifications.length})'),
                _buildFilterChip('unread', 'Unread ($unreadCount)'),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final n = filtered[idx];
                final isUnread = n['unread'] == true;

                return Card(
                  color: isUnread ? AppTheme.surfaceCard : AppTheme.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isUnread ? AppTheme.primaryTeal.withValues(alpha: 0.3) : AppTheme.hairlineBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => n['unread'] = false);
                      if (n['ticket_id'] != null) {
                        context.push('/tickets/${n['ticket_id']}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isUnread ? AppTheme.primaryTeal.withValues(alpha: 0.15) : AppTheme.surfaceContainer,
                            child: Icon(
                              n['type'] == 'message' ? Icons.chat_bubble_outline : Icons.notifications_active_outlined,
                              size: 18,
                              color: isUnread ? AppTheme.primaryTeal : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'] as String,
                                        style: TextStyle(
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] as String,
                                  style: TextStyle(fontSize: 13, color: isUnread ? AppTheme.textPrimary : AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
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
        onSelected: (_) => setState(() => _activeFilter = value),
      ),
    );
  }
}
