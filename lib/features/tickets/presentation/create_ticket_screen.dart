import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import 'widgets/dynamic_field_form.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../../core/widgets/offline_banner.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  int _priority = 0;
  Map<String, dynamic> _customValues = {};
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(ticketRepositoryProvider);
      await repo.createTicket(
        subject: _subjectController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        customFields: _customValues,
      );
      // Invalidate tickets provider to refresh list
      ref.invalidate(ticketsProvider);
      if (!mounted) return;
      AppDialogs.showSuccessSnackbar(context, 'Ticket created successfully.');
      context.pop();
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, title: 'Could Not Create Ticket', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemaAsync = ref.watch(schemaProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCanvas,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ),
        leadingWidth: 80,
        centerTitle: true,
        title: const Column(
          children: [
            Text('Create Ticket', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('Incident Dispatch', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 16),
              label: const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Fast SLA Route Banner (from Stitch c2)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.hairlineBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt, size: 18, color: AppTheme.primaryTeal),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Support Queue Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                              Text('Dispatched directly into Odoo Helpdesk workflow', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Auto-route', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),



                  // Section: Core Details
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
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Ticket Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject *',
                              hintText: 'Brief summary of the issue',
                              prefixIcon: Icon(Icons.title, size: 20, color: AppTheme.textSecondary),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Subject is required' : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _descController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              hintText: 'Provide detailed information about the problem...',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Priority Star Selection (Odoo: 0 = Low, 1 = Medium, 2 = High, 3 = Urgent)
                          const Text('Priority Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(3, (index) {
                                final starNum = index + 1;
                                final isSelected = starNum <= _priority;
                                return IconButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: isSelected ? const Color(0xFFF59E0B) : AppTheme.textMuted,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_priority == starNum) {
                                        _priority = 0;
                                      } else {
                                        _priority = starNum;
                                      }
                                    });
                                  },
                                );
                              }),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _priority == 3
                                        ? const Color(0xFFFEE2E2)
                                        : _priority == 2
                                            ? const Color(0xFFFEF3C7)
                                            : _priority == 1
                                                ? const Color(0xFFE0F2FE)
                                                : AppTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _priority == 3
                                        ? 'Urgent (3 Stars)'
                                        : _priority == 2
                                            ? 'High (2 Stars)'
                                            : _priority == 1
                                                ? 'Medium (1 Star)'
                                                : 'Low (No Stars)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _priority == 3
                                          ? const Color(0xFF991B1B)
                                          : _priority == 2
                                              ? const Color(0xFF92400E)
                                              : _priority == 1
                                                  ? const Color(0xFF0369A1)
                                                  : AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Dynamic Schema Fields
                  schemaAsync.when(
                    data: (schema) {
                      final createFields = schema.fields.where((f) => f.showOnCreate).toList();
                      if (createFields.isEmpty) return const SizedBox.shrink();
                      return Card(
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
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryAubergine,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Additional Custom Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DynamicFieldForm(
                                fields: createFields,
                                values: _customValues,
                                onChanged: (vals) => setState(() => _customValues = vals),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
                    ),
                    error: (err, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Submit CTA
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
