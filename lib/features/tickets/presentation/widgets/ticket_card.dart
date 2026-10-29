import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final status = AppTheme.getStatusToken(
      ticket.stage.name,
      isClosed: ticket.stage.isClosed,
      sequence: ticket.stage.sequence,
    );

    final assignee = ticket.assignee;
    final customer = ticket.customer;
    final relativeTime = Formatters.formatRelativeTime(ticket.updatedAt ?? ticket.createdAt);

    return Card(
      color: AppTheme.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryTeal
              : AppTheme.hairlineBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 4),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: onSelectChanged,
                    activeColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Mono ID, Priority Stars, Stage Pill
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (ticket.priority > 0) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  ticket.priority,
                                  (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Stage Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status.container,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: status.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: status.foreground,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ticket.stage.name,
                                style: TextStyle(
                                  color: status.foreground,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ticket Subject
                    Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Customer Row
                    if (customer != null && customer.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.email != null && customer.email!.isNotEmpty
                                    ? '${customer.name} (${customer.email})'
                                    : customer.name,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Prominent Employee Assignee Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: assignee != null
                            ? AppTheme.surfaceContainerLow
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: assignee != null
                              ? AppTheme.hairlineBorder
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: assignee != null
                                ? AppTheme.primaryTeal.withValues(alpha: 0.18)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            child: assignee != null
                                ? Text(
                                    assignee.name.isNotEmpty ? assignee.name[0].toUpperCase() : 'E',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_search_rounded,
                                    size: 16,
                                    color: Color(0xFFB45309),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignee != null
                                      ? assignee.name
                                      : 'Unassigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: assignee != null
                                        ? AppTheme.textPrimary
                                        : const Color(0xFFB45309),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (assignee != null && (assignee.jobTitle.isNotEmpty || assignee.department.isNotEmpty))
                                  Text(
                                    [assignee.jobTitle, assignee.department]
                                        .where((s) => s.isNotEmpty)
                                        .join(' • '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (assignee == null)
                                  const Text(
                                    'Action required: Triage and assign employee',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (assignee != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Employee',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Custom Fields (Polished, Humanized Labels, Non-Developer Syntax)
                    if (ticket.custom.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: ticket.custom.entries.take(2).map((entry) {
                          final label = Formatters.humanizeFieldName(entry.key);
                          final value = Formatters.formatCustomValue(entry.value);
                          if (value.isEmpty || value == 'No') {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$label: $value',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Footer Row: Tags & Relative Time
                    Row(
                      children: [
                        if (ticket.tags.isNotEmpty)
                          ...ticket.tags.take(2).map(
                                (tag) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                        const Spacer(),
                        if (relativeTime.isNotEmpty) ...[
                          const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            relativeTime,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
