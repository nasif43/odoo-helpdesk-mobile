import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/ticket.dart';
import '../domain/ticket_fields_schema.dart';
import '../domain/ticket_repository.dart';

class DioTicketRepository implements TicketRepository {
  final ApiClient apiClient;

  DioTicketRepository({ApiClient? client}) : apiClient = client ?? ApiClient();

  @override
  Future<List<Ticket>> getTickets({
    int page = 1,
    int pageSize = 20,
    String? stageGroup,
    String? query,
    Map<String, String>? customFilters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (stageGroup != null && stageGroup.isNotEmpty) {
        queryParams['stage_group'] = stageGroup;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (customFilters != null) {
        queryParams.addAll(customFilters);
      }

      final res = await apiClient.dio.get('/tickets', queryParameters: queryParams);
      final list = res.data['data'] as List;
      return list.map((item) => Ticket.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> getTicket(int id) async {
    try {
      final res = await apiClient.dio.get('/tickets/$id');
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> createTicket({
    required String subject,
    required String description,
    int priority = 0,
    Map<String, dynamic>? customFields,
    List<int>? attachmentIds,
  }) async {
    try {
      final res = await apiClient.dio.post('/tickets', data: {
        'subject': subject,
        'description': description,
        'priority': priority,
        'custom': ?customFields,
        'attachment_ids': ?attachmentIds,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<TicketStage>> getStages() async {
    try {
      final res = await apiClient.dio.get('/meta/stages');
      final list = res.data['data'] as List;
      return list.map((s) => TicketStage.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<FieldsSchemaResponse> getFieldsSchema() async {
    try {
      final res = await apiClient.dio.get('/meta/ticket-fields');
      return FieldsSchemaResponse.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(int ticketId) async {
    try {
      final res = await apiClient.dio.get('/tickets/$ticketId/messages');
      return List<Map<String, dynamic>>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> postMessage(int ticketId, String body, {bool internal = false}) async {
    try {
      await apiClient.dio.post('/tickets/$ticketId/messages', data: {
        'body': body,
        'internal': internal,
      });
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> confirmResolution(int ticketId) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/confirm');
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> reopenTicket(int ticketId, String reason) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/reopen', data: {
        'reason': reason,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> submitRating(int ticketId, int rating, String? comment) async {
    try {
      await apiClient.dio.post('/tickets/$ticketId/rating', data: {
        'rating': rating,
        'comment': comment,
      });
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> approveTicket(int ticketId, {int? priority, int? assigneeId, String? comment}) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/approve', data: {
        'priority': ?priority,
        'assignee_id': ?assigneeId,
        'comment': ?comment,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> rejectTicket(int ticketId, String reason) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/reject', data: {
        'reason': reason,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> assignTicket(int ticketId, int? assigneeId) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/assign', data: {
        'assignee_id': assigneeId,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Ticket> changeStage(int ticketId, int stageId, {String? comment}) async {
    try {
      final res = await apiClient.dio.post('/tickets/$ticketId/stage', data: {
        'stage_id': stageId,
        'comment': ?comment,
      });
      return Ticket.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final res = await apiClient.dio.get('/dashboard');
      return Map<String, dynamic>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomers({int page = 1, String? query}) async {
    try {
      final res = await apiClient.dio.get('/customers', queryParameters: {
        'page': page,
        if (query != null && query.isNotEmpty) 'q': query,
      });
      return List<Map<String, dynamic>>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final res = await apiClient.dio.get('/meta/agents');
      return List<Map<String, dynamic>>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> bulkUpdateTickets({
    required String action,
    required List<int> ticketIds,
    Map<String, dynamic>? params,
  }) async {
    try {
      final res = await apiClient.dio.post('/tickets/bulk', data: {
        'action': action,
        'ids': ticketIds,
        'params': ?params,
      });
      return Map<String, dynamic>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(int ticketId) async {
    try {
      final res = await apiClient.dio.get('/tickets/$ticketId/history');
      return List<Map<String, dynamic>>.from(res.data['data']);
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
