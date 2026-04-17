import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// High-priority notification channel — bypass DND, alarm sound.
  static const _alarmChannelId = 'santa_maria_alarm';
  static const _alarmChannelName = 'Santa Maria Alarm';

  String? get token => _token;

  /// Initialize FCM — call after login.
  /// Registers device token with backend for push notifications.
  Future<void> init() async {
    try {
      // Set up Android alarm notification channel (Importance.max + fullScreenIntent)
      await _setupAlarmChannel();

      // In production, use firebase_messaging package:
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission(
      //   alert: true, badge: true, sound: true,
      //   criticalAlert: true,  // bypass DND on iOS
      // );
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

  /// Create a MAX-importance notification channel so every push notification
  /// plays an alarm sound, vibrates, and bypasses Do Not Disturb.
  Future<void> _setupAlarmChannel() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidChannel = AndroidNotificationChannel(
      _alarmChannelId,
      _alarmChannelName,
      description: 'Semua notifikasi Santa Maria — alarm bypass DND',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize the plugin so we can show local notifications from foreground
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
        ),
      ),
    );
  }

  /// Register FCM token with backend.
  Future<void> _registerToken(String token) async {
    try {
      await _api.dio.post('/auth/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Handle foreground message — route to NotificationHandler + show local notification.
  void handleForegroundMessage(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>? ?? message;
    NotificationHandler.instance.handleNotification(data);

    // Also show a system-level local notification via the alarm channel
    // so the sound/vibration fires even if the app is in foreground.
    _showLocalAlarmNotification(
      title: data['title'] as String? ?? 'Santa Maria',
      body: data['body'] as String? ?? '',
    );
  }

  /// Show a local notification on the MAX-importance alarm channel.
  Future<void> _showLocalAlarmNotification({
    required String title,
    required String body,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _alarmChannelId,
            _alarmChannelName,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
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
