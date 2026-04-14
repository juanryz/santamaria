import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import 'notification_handler.dart';

/// Firebase Cloud Messaging service — handles token registration and message routing.
/// Actual firebase_messaging initialization depends on native setup (google-services.json).
/// This service provides the integration layer between FCM and the app.
class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  final ApiClient _api = ApiClient();
  String? _token;

  String? get token => _token;

  /// Initialize FCM — call after login.
  /// Registers device token with backend for push notifications.
  Future<void> init() async {
    try {
      // In production, use firebase_messaging package:
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission(alert: true, badge: true, sound: true, criticalAlert: true);
      // _token = await messaging.getToken();

      // For now, use a placeholder — replace with actual FCM init
      _token = 'fcm_token_placeholder_${DateTime.now().millisecondsSinceEpoch}';

      if (_token != null) {
        await _registerToken(_token!);
      }

      // Listen for foreground messages
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for background/terminated tap
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      debugPrint('FCM initialized. Token: ${_token?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  /// Register FCM token with backend.
  Future<void> _registerToken(String token) async {
    try {
      await _api.dio.post('/auth/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Handle foreground message — route to NotificationHandler.
  void handleForegroundMessage(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>? ?? message;
    NotificationHandler.instance.handleNotification(data);
  }

  /// Handle background message tap — navigate to relevant screen.
  void handleMessageTap(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>? ?? message;
    final action = data['action'] as String?;
    final orderId = data['order_id'] as String?;

    // Navigation will be handled by NotificationHandler or deep link router
    debugPrint('FCM tap: action=$action, orderId=$orderId');
  }

  /// Cleanup — call on logout.
  Future<void> dispose() async {
    _token = null;
  }
}
