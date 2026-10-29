import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_helpdesk_mobile/features/tickets/data/mock_ticket_repository.dart';
import 'package:odoo_helpdesk_mobile/features/tickets/domain/ticket.dart';
import 'package:odoo_helpdesk_mobile/features/auth/domain/user.dart';

void main() {
  group('MockTicketRepository Tests', () {
    late MockTicketRepository repo;

    setUp(() {
      repo = MockTicketRepository();
    });

    test('Initial tickets loaded and stage filtering works', () async {
      final allTickets = await repo.getTickets();
      expect(allTickets.length, 5);

      final openTickets = await repo.getTickets(stageGroup: 'open');
      expect(openTickets.every((t) => ['New', 'Approved'].contains(t.stage.name)), isTrue);

      final inProgressTickets = await repo.getTickets(stageGroup: 'in_progress');
      expect(inProgressTickets.every((t) => ['Tracking', 'Work In Progress', 'Solving'].contains(t.stage.name)), isTrue);
    });

    test('Admin approves ticket in stage New', () async {
      final approved = await repo.approveTicket(1, priority: 2, comment: 'Ready for assignment');
      expect(approved.stage.name, 'Approved');
      expect(approved.priority, 2);
    });

    test('Customer confirm moves ticket to Done', () async {
      final done = await repo.confirmResolution(3);
      expect(done.stage.name, 'Done');
      expect(done.can('reopen'), isTrue);
      expect(done.can('rate'), isTrue);
      expect(done.can('reply'), isFalse);
    });

    test('Customer reopen returns ticket to Work In Progress', () async {
      final reopened = await repo.reopenTicket(4, 'Issue still occurring');
      expect(reopened.stage.name, 'Work In Progress');
      expect(reopened.can('reply'), isTrue);
    });

    test('Dynamic schema loads custom fields with types', () async {
      final schema = await repo.getFieldsSchema();
      expect(schema.fields.isNotEmpty, isTrue);
      expect(schema.fields.any((f) => f.name == 'x_site_location' && f.type == 'selection'), isTrue);
      expect(schema.fields.any((f) => f.name == 'x_requires_onsite' && f.type == 'boolean'), isTrue);
    });

    test('Bulk operations execute across multiple tickets', () async {
      final res = await repo.bulkUpdateTickets(
        action: 'approve',
        ticketIds: [1, 2],
      );
      final results = res['results'] as List;
      expect(results.length, 2);
      expect(results.every((r) => r['ok'] == true), isTrue);
    });

    test('Agents directory loads with open workload counts', () async {
      final agents = await repo.getAgents();
      expect(agents.isNotEmpty, isTrue);
      expect(agents.first.containsKey('open_tickets_count'), isTrue);
    });

    test('Ticket history loads chronologically', () async {
      final history = await repo.getHistory(1);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.containsKey('description'), isTrue);
    });

    test('Exact 7 Team Stages returned', () async {
      final stages = await repo.getStages();
      expect(stages.length, 7);
      expect(stages.map((s) => s.name).toList(), [
        'New',
        'Approved',
        'Tracking',
        'Work In Progress',
        'Solving',
        'Done',
        'Rejected'
      ]);
    });

    test('Ticket.fromJson parses resiliently with string or int priority', () {
      final mapWithStr = {
        'id': '10',
        'number': '#10',
        'subject': 'Resilience Test',
        'stage': {'id': 1, 'name': 'New', 'sequence': 1, 'is_closed': false},
        'priority': '3',
      };
      final ticket = Ticket.fromJson(mapWithStr);
      expect(ticket.id, 10);
      expect(ticket.priority, 3);
    });

    test('User.fromJson deserializes employee_id for admin user', () {
      final userMap = {
        'id': 5,
        'employee_id': 2,
        'name': 'Marcus Vance',
        'email': 'admin@helpdesk.local',
        'role': 'admin',
        'partner_id': 9,
      };
      final user = User.fromJson(userMap);
      expect(user.id, 5);
      expect(user.employeeId, 2);
      expect(user.isAdmin, isTrue);
    });
  });
}
