import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/offline_banner.dart';

final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getCustomers();
});

class CustomersDirectoryScreen extends ConsumerWidget {
  const CustomersDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers Directory')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final c = customers[idx];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          ref.read(ticketFilterProvider.notifier).state = TicketFilterState(query: c['name'] ?? '');
                          context.push('/admin/tickets');
                        },
                        leading: CircleAvatar(
                          child: Text(c['name']?[0] ?? 'C'),
                        ),
                        title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${c['email'] ?? ''} • ${c['phone'] ?? ''}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${c['total_tickets']} tickets',
                            style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
