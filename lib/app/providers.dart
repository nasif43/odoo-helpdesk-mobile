import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/user.dart';
import '../features/auth/data/dio_auth_repository.dart';
import '../features/tickets/domain/ticket_repository.dart';
import '../features/tickets/domain/ticket.dart';
import '../features/tickets/domain/ticket_fields_schema.dart';
import '../features/tickets/data/dio_ticket_repository.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DioAuthRepository();
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return DioTicketRepository();
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(email, password);
      state = AsyncValue.data(user);
      _ref.invalidate(ticketFilterProvider);
      _ref.invalidate(ticketsProvider);
      _ref.invalidate(dashboardMetricsProvider);
      _ref.invalidate(agentsProvider);
      _ref.invalidate(stagesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String phone) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(name, email, password, phone);
      state = AsyncValue.data(user);
      _ref.invalidate(ticketsProvider);
      _ref.invalidate(dashboardMetricsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
    _ref.invalidate(ticketFilterProvider);
    _ref.invalidate(ticketsProvider);
    _ref.invalidate(dashboardMetricsProvider);
    _ref.invalidate(agentsProvider);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

// Tickets State
class TicketFilterState {
  final String stageGroup;
  final String query;

  const TicketFilterState({this.stageGroup = 'all', this.query = ''});

  TicketFilterState copyWith({String? stageGroup, String? query}) {
    return TicketFilterState(
      stageGroup: stageGroup ?? this.stageGroup,
      query: query ?? this.query,
    );
  }
}

final ticketFilterProvider = StateProvider<TicketFilterState>((ref) {
  return const TicketFilterState();
});

final ticketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final filter = ref.watch(ticketFilterProvider);
  return repo.getTickets(
    stageGroup: filter.stageGroup == 'all' ? null : filter.stageGroup,
    query: filter.query,
  );
});

final stagesProvider = FutureProvider<List<TicketStage>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getStages();
});

final schemaProvider = FutureProvider<FieldsSchemaResponse>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getFieldsSchema();
});

final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getDashboardMetrics();
});

final agentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getAgents();
});

final ticketHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getHistory(ticketId);
});
