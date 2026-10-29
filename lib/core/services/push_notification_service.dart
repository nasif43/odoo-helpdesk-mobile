import 'dart:io';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  bool _isConfigured = false;
  String? _currentToken;

  bool get isConfigured => _isConfigured;
  String? get currentToken => _currentToken;

  /// Initializes push notification integration.
  /// For local demo without active Google Services/FCM keys, runs gracefully in simulated mode.
  Future<void> init({bool enableFcm = false, ApiClient? apiClient}) async {
    _isConfigured = enableFcm;
    if (!enableFcm) {
      debugPrint('[PushNotificationService] Push notifications configured in simulated demo mode.');
      return;
    }

    try {
      // In production, FirebaseMessaging.instance.getToken() would be called.
      // In demo mode with enableFcm=true, we register a sample device token.
      _currentToken = 'demo_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      if (apiClient != null) {
        await registerDeviceWithBackend(apiClient, _currentToken!);
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to initialize FCM: $e');
    }
  }

  Future<void> registerDeviceWithBackend(ApiClient apiClient, String token) async {
    try {
      final platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');
      await apiClient.post('/me/devices', data: {
        'token': token,
        'platform': platform,
        'app_version': '1.0.0',
      });
      debugPrint('[PushNotificationService] Device token registered with Odoo: $token');
    } catch (e) {
      debugPrint('[PushNotificationService] Device registration failed: $e');
    }
  }

  Future<void> unregisterDevice(ApiClient apiClient) async {
    if (_currentToken == null) return;
    try {
      await apiClient.dio.delete('/me/devices/$_currentToken');
      _currentToken = null;
      debugPrint('[PushNotificationService] Device token unregistered');
    } catch (e) {
      debugPrint('[PushNotificationService] Device unregistration error: $e');
    }
  }

  /// Handles deep links from push notification payload (e.g. {"ticket_id": 128})
  String? parseDeepLinkTicketRoute(Map<String, dynamic> payload) {
    if (payload.containsKey('ticket_id')) {
      final ticketId = payload['ticket_id'];
      return '/tickets/$ticketId';
    }
    return null;
  }
}
