import 'ticket.dart';
import 'ticket_fields_schema.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getTickets({
    int page = 1,
    int pageSize = 20,
    String? stageGroup,
    String? query,
    Map<String, String>? customFilters,
  });

  Future<Ticket> getTicket(int id);

  Future<Ticket> createTicket({
    required String subject,
    required String description,
    int priority = 0,
    Map<String, dynamic>? customFields,
    List<int>? attachmentIds,
  });

  Future<List<TicketStage>> getStages();
  Future<FieldsSchemaResponse> getFieldsSchema();

  Future<List<Map<String, dynamic>>> getMessages(int ticketId);
  Future<void> postMessage(int ticketId, String body, {bool internal = false});

  // Customer actions
  Future<Ticket> confirmResolution(int ticketId);
  Future<Ticket> reopenTicket(int ticketId, String reason);
  Future<void> submitRating(int ticketId, int rating, String? comment);

  // Admin actions
  Future<Ticket> approveTicket(int ticketId, {int? priority, int? assigneeId, String? comment});
  Future<Ticket> rejectTicket(int ticketId, String reason);
  Future<Ticket> assignTicket(int ticketId, int? assigneeId);
  Future<Ticket> changeStage(int ticketId, int stageId, {String? comment});
  Future<Map<String, dynamic>> getDashboardMetrics();
  Future<List<Map<String, dynamic>>> getCustomers({int page = 1, String? query});
  Future<List<Map<String, dynamic>>> getAgents();
  Future<Map<String, dynamic>> bulkUpdateTickets({
    required String action,
    required List<int> ticketIds,
    Map<String, dynamic>? params,
  });
  Future<List<Map<String, dynamic>>> getHistory(int ticketId);
}
