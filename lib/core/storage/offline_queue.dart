import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../network/api_client.dart';

class QueuedAction {
  final String id;
  final String idempotencyKey;
  final String endpoint;
  final String method;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  QueuedAction({
    required this.id,
    required this.idempotencyKey,
    required this.endpoint,
    required this.method,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'endpoint': endpoint,
        'method': method,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
        id: json['id'] as String,
        idempotencyKey: json['idempotencyKey'] as String,
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

class OfflineSyncEngine {
  static const String _storageKey = 'offline_actions_queue_v1';
  static final OfflineSyncEngine instance = OfflineSyncEngine._();

  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

  OfflineSyncEngine._();

  Future<void> init() async {
    final queue = await _loadQueue();
    pendingCountNotifier.value = queue.length;
  }

  Future<List<QueuedAction>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => QueuedAction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<QueuedAction> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
    pendingCountNotifier.value = queue.length;
  }

  Future<String> enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    String? customIdempotencyKey,
  }) async {
    final key = customIdempotencyKey ?? const Uuid().v4();
    final action = QueuedAction(
      id: const Uuid().v4(),
      idempotencyKey: key,
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: DateTime.now(),
    );

    final queue = await _loadQueue();
    queue.add(action);
    await _saveQueue(queue);
    return key;
  }

  Future<int> processPendingQueue(ApiClient apiClient) async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return 0;

    int syncedCount = 0;
    final remaining = <QueuedAction>[];

    for (final action in queue) {
      try {
        if (action.method == 'POST') {
          await apiClient.post(
            action.endpoint,
            data: action.data,
            headers: {'Idempotency-Key': action.idempotencyKey},
          );
        } else if (action.method == 'PATCH') {
          await apiClient.patch(
            action.endpoint,
            data: action.data,
            headers: {'Idempotency-Key': action.idempotencyKey},
          );
        }
        syncedCount++;
      } catch (e) {
        action.retryCount++;
        if (action.retryCount < 5) {
          remaining.add(action);
        }
      }
    }

    await _saveQueue(remaining);
    return syncedCount;
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    pendingCountNotifier.value = 0;
  }
}
