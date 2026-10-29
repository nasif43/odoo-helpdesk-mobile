import '../domain/ticket.dart';
import '../domain/ticket_fields_schema.dart';
import '../domain/ticket_repository.dart';

class MockTicketRepository implements TicketRepository {
  final List<Ticket> _tickets = [];
  final List<TicketStage> _stages = const [
    TicketStage(id: 1, name: 'New', sequence: 1, isClosed: false, fold: false),
    TicketStage(id: 18, name: 'Approved', sequence: 2, isClosed: false, fold: false),
    TicketStage(id: 19, name: 'Tracking', sequence: 3, isClosed: false, fold: false),
    TicketStage(id: 20, name: 'Work In Progress', sequence: 4, isClosed: false, fold: false),
    TicketStage(id: 21, name: 'Solving', sequence: 5, isClosed: false, fold: false),
    TicketStage(id: 22, name: 'Done', sequence: 6, isClosed: true, fold: true),
    TicketStage(id: 23, name: 'Rejected', sequence: 7, isClosed: true, fold: true),
  ];

  MockTicketRepository() {
    _tickets.addAll([
      Ticket(
        id: 1,
        number: '#1',
        subject: 'Cannot access inventory portal',
        stage: _stages[0],
        priority: 2,
        customer: const {'id': 10, 'name': 'John Doe', 'email': 'customer1@acme.com'},
        allowedActions: const ['reply'],
        custom: const {'x_site_location': 'hq', 'x_requires_onsite': false},
        description: 'Receiving 504 gateway timeout on stock query API.',
      ),
      Ticket(
        id: 2,
        number: '#2',
        subject: 'Printer offline in Accounts',
        stage: _stages[3],
        priority: 1,
        assignee: const {'id': 5, 'name': 'Marcus Vance'},
        customer: const {'id': 10, 'name': 'John Doe', 'email': 'customer1@acme.com'},
        allowedActions: const ['reply'],
        custom: const {'x_site_location': 'branch_dhaka', 'x_requires_onsite': true},
        description: 'Network printer not responding to ping or print jobs.',
      ),
      Ticket(
        id: 3,
        number: '#3',
        subject: 'Switch port flapping in Server Room',
        stage: _stages[4],
        priority: 3,
        assignee: const {'id': 5, 'name': 'Marcus Vance'},
        customer: const {'id': 10, 'name': 'John Doe', 'email': 'customer1@acme.com'},
        allowedActions: const ['reply', 'confirm'],
        custom: const {'x_site_location': 'hq', 'x_requires_onsite': true},
        description: 'Port 24 is dropping packets intermittently.',
      ),
      Ticket(
        id: 4,
        number: '#4',
        subject: 'New ergonomic mouse request',
        stage: _stages[5],
        priority: 0,
        assignee: const {'id': 5, 'name': 'Marcus Vance'},
        customer: const {'id': 11, 'name': 'Jane Smith', 'email': 'customer2@globex.com'},
        allowedActions: const ['reopen', 'rate'],
        custom: const {'x_site_location': 'remote'},
        description: 'Requesting vertical mouse for UX design work.',
      ),
      Ticket(
        id: 5,
        number: '#5',
        subject: 'Request for company sponsored iPad Pro',
        stage: _stages[6],
        priority: 0,
        customer: const {'id': 11, 'name': 'Jane Smith', 'email': 'customer2@globex.com'},
        allowedActions: const ['reopen'],
        rejectionReason: 'Outside company equipment allowance policy.',
        custom: const {'x_site_location': 'remote'},
        description: 'Need personal tablet for leisure reading.',
      ),
    ]);
  }

  @override
  Future<List<Ticket>> getTickets({
    int page = 1,
    int pageSize = 20,
    String? stageGroup,
    String? query,
    Map<String, String>? customFilters,
  }) async {
    var filtered = List<Ticket>.from(_tickets);
    if (stageGroup != null && stageGroup.isNotEmpty) {
      if (stageGroup == 'open') {
        filtered = filtered.where((t) => ['New', 'Approved'].contains(t.stage.name)).toList();
      } else if (stageGroup == 'in_progress') {
        filtered = filtered.where((t) => ['Tracking', 'Work In Progress', 'Solving'].contains(t.stage.name)).toList();
      } else if (stageGroup == 'done') {
        filtered = filtered.where((t) => t.stage.name == 'Done').toList();
      } else if (stageGroup == 'rejected') {
        filtered = filtered.where((t) => t.stage.name == 'Rejected').toList();
      }
    }
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where((t) => t.subject.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return filtered;
  }

  @override
  Future<Ticket> getTicket(int id) async {
    return _tickets.firstWhere((t) => t.id == id);
  }

  @override
  Future<Ticket> createTicket({
    required String subject,
    required String description,
    int priority = 0,
    Map<String, dynamic>? customFields,
    List<int>? attachmentIds,
  }) async {
    final newTicket = Ticket(
      id: _tickets.length + 1,
      number: '#${_tickets.length + 1}',
      subject: subject,
      stage: _stages[0],
      priority: priority,
      description: description,
      custom: customFields ?? {},
      allowedActions: const ['reply'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tickets.insert(0, newTicket);
    return newTicket;
  }

  @override
  Future<List<TicketStage>> getStages() async => _stages;

  @override
  Future<FieldsSchemaResponse> getFieldsSchema() async {
    return const FieldsSchemaResponse(
      version: 'mock-1.0',
      fields: [
        SchemaField(
          name: 'x_site_location',
          label: 'Site Location',
          type: 'selection',
          section: 'Site Details',
          sequence: 10,
          required: true,
          options: [
            SchemaFieldOption(value: 'hq', label: 'Headquarters'),
            SchemaFieldOption(value: 'branch_dhaka', label: 'Dhaka Branch'),
            SchemaFieldOption(value: 'branch_ctg', label: 'Chittagong Branch'),
            SchemaFieldOption(value: 'remote', label: 'Remote Site'),
          ],
        ),
        SchemaField(
          name: 'x_urgency_notes',
          label: 'Urgency Notes',
          type: 'text',
          section: 'Incident Info',
          sequence: 20,
        ),
        SchemaField(
          name: 'x_requires_onsite',
          label: 'Requires On-Site Visit',
          type: 'boolean',
          section: 'Incident Info',
          sequence: 30,
          showInList: true,
        ),
        SchemaField(
          name: 'x_incident_date',
          label: 'Incident Date',
          type: 'date',
          section: 'Timeline',
          sequence: 40,
        ),
      ],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(int ticketId) async => [
        {'id': 1, 'author': {'id': 10, 'name': 'John Doe'}, 'body': 'Ticket created', 'is_internal': false},
      ];

  @override
  Future<void> postMessage(int ticketId, String body, {bool internal = false}) async {}

  @override
  Future<Ticket> confirmResolution(int ticketId) async {
    final t = await getTicket(ticketId);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: _stages[5],
      priority: t.priority,
      allowedActions: const ['reopen', 'rate'],
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<Ticket> reopenTicket(int ticketId, String reason) async {
    final t = await getTicket(ticketId);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: _stages[3],
      priority: t.priority,
      allowedActions: const ['reply'],
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<void> submitRating(int ticketId, int rating, String? comment) async {}

  @override
  Future<Ticket> approveTicket(int ticketId, {int? priority, int? assigneeId, String? comment}) async {
    final t = await getTicket(ticketId);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: _stages[1],
      priority: priority ?? t.priority,
      allowedActions: const ['change_stage', 'assign', 'edit_details', 'internal_note', 'reply'],
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<Ticket> rejectTicket(int ticketId, String reason) async {
    final t = await getTicket(ticketId);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: _stages[6],
      priority: t.priority,
      rejectionReason: reason,
      allowedActions: const ['reopen'],
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<Ticket> assignTicket(int ticketId, int? assigneeId) async {
    final t = await getTicket(ticketId);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: t.stage,
      priority: t.priority,
      assignee: {'id': assigneeId ?? 5, 'name': 'Assigned Agent'},
      allowedActions: t.allowedActions,
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<Ticket> changeStage(int ticketId, int stageId, {String? comment}) async {
    final t = await getTicket(ticketId);
    final st = _stages.firstWhere((s) => s.id == stageId, orElse: () => _stages[3]);
    final updated = Ticket(
      id: t.id,
      number: t.number,
      subject: t.subject,
      stage: st,
      priority: t.priority,
      allowedActions: const ['change_stage', 'assign', 'edit_details', 'internal_note', 'reply'],
      description: t.description,
      custom: t.custom,
    );
    _replaceTicket(updated);
    return updated;
  }

  @override
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    return {
      'awaiting_approval': 1,
      'unassigned': 1,
      'urgent': 1,
      'mine': 3,
      'stages': _stages.map((s) => {'id': s.id, 'name': s.name, 'count': 1}).toList(),
      'recent_tickets': _tickets.take(5).toList(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomers({int page = 1, String? query}) async {
    return [
      {'id': 10, 'name': 'John Doe', 'email': 'customer1@acme.com', 'total_tickets': 3, 'open_tickets': 2},
      {'id': 11, 'name': 'Jane Smith', 'email': 'customer2@globex.com', 'total_tickets': 2, 'open_tickets': 0},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getAgents() async {
    return [
      {'id': 5, 'name': 'Marcus Vance', 'email': 'admin@helpdesk.local', 'open_tickets_count': 3},
      {'id': 6, 'name': 'Senior Support Agent', 'email': 'agent1@helpdesk.local', 'open_tickets_count': 1},
    ];
  }

  @override
  Future<Map<String, dynamic>> bulkUpdateTickets({
    required String action,
    required List<int> ticketIds,
    Map<String, dynamic>? params,
  }) async {
    final results = <Map<String, dynamic>>[];
    for (final id in ticketIds) {
      if (action == 'approve') {
        await approveTicket(id);
      } else if (action == 'assign') {
        await assignTicket(id, params?['assignee_id']);
      } else if (action == 'stage') {
        await changeStage(id, params?['stage_id'] ?? 1);
      }
      results.add({'id': id, 'ok': true});
    }
    return {'results': results};
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(int ticketId) async {
    return [
      {'id': 1, 'date': '2026-10-28T10:00:00Z', 'author': 'System', 'description': 'Ticket created in stage New'},
      {'id': 2, 'date': '2026-10-28T10:15:00Z', 'author': 'Marcus Vance', 'description': 'Stage changed from New to Approved'},
    ];
  }

  void _replaceTicket(Ticket updated) {
    final idx = _tickets.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _tickets[idx] = updated;
    }
  }
}
