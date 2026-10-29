import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odoo_helpdesk_mobile/main.dart';
import 'package:odoo_helpdesk_mobile/app/providers.dart';
import 'package:odoo_helpdesk_mobile/features/tickets/data/mock_ticket_repository.dart';

void main() {
  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(MockTicketRepository()),
        ],
        child: const OdooHelpdeskApp(),
      ),
    );

    expect(find.text('Odoo Desk'), findsOneWidget);
    expect(find.text('Enterprise Support & SLA Orchestration'), findsOneWidget);

    // Pump timer so splash screen delay finishes
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
