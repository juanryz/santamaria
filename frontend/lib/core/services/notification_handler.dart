import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/glass_alarm_overlay.dart';
import 'alarm_service.dart';

/// Notification handler — processes incoming FCM/Pusher notifications
/// and shows appropriate UI (alarm overlay, snackbar, etc.)
class NotificationHandler {
  static final NotificationHandler instance = NotificationHandler._();
  NotificationHandler._();

  GlobalKey<NavigatorState>? _navigatorKey;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Handle an incoming notification payload.
  void handleNotification(Map<String, dynamic> payload) {
    final priority = payload['priority'] ?? 'NORMAL';
    final title = payload['title'] ?? '';
    final body = payload['body'] ?? '';
    final orderId = payload['order_id'];
    final action = payload['action'];

    // ALL notifications play alarm sound that bypasses DND (owner requirement).
    // Visual presentation differs by priority.
    final alarmMessage = '$title. $body';
    AlarmService().playLoudAlarm(message: alarmMessage);

    switch (priority) {
      case 'ALARM':
      case 'VERY_HIGH':
        _showAlarmOverlay(title, body, orderId: orderId, action: action);
        break;
      case 'HIGH':
        _showAlarmOverlay(title, body, orderId: orderId, action: action);
        break;
      default:
        _showSnackbar(title, body);
    }
  }

  /// Handle Pusher event data.
  void handlePusherEvent(String eventName, dynamic data) {
    final parsed = data is String ? jsonDecode(data) : data;

    switch (eventName) {
      case 'equipment.updated':
        _showSnackbar('Peralatan Diperbarui', parsed['action'] ?? '');
        break;
      case 'attendance.updated':
        _showSnackbar('Presensi', '${parsed['role'] ?? ''}: ${parsed['status'] ?? ''}');
        break;
      case 'coffin.updated':
        _showSnackbar('Workshop Peti', 'Status: ${parsed['status'] ?? ''}');
        break;
      case 'kpi.calculated':
        _showSnackbar('KPI', 'Skor KPI periode ${parsed['periodName'] ?? ''} diperbarui');
        break;
      case 'stock.alert':
        _showAlarmOverlay('Stok Alert!', parsed['message'] ?? '');
        break;
      case 'owner.command':
        _handleOwnerCommand(Map<String, dynamic>.from(parsed as Map));
        break;
    }
  }

  /// Perintah langsung dari owner — alarm paksa + overlay tidak bisa di-dismiss
  /// sampai karyawan menekan "Siap Laksanakan".
  void _handleOwnerCommand(Map<String, dynamic> data) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final commandId = data['command_id'] as String? ?? '';
    final title     = data['title'] as String? ?? 'Perintah Owner';
    final message   = data['message'] as String? ?? '';
    final priority  = data['priority'] as String? ?? 'normal';
    final ownerName = data['owner_name'] as String? ?? 'Owner';

    // Bunyikan alarm TTS sesuai priority
    final ttsMessage = priority == 'urgent'
        ? 'Perintah mendesak dari $ownerName! $title. $message'
        : 'Perintah dari $ownerName. $title.';
    AlarmService().playLoudAlarm(message: ttsMessage);

    // Tampilkan overlay — barrierDismissible: false agar tidak bisa diabaikan
    showAlarmOverlay(
      context,
      title: '📋 $title',
      message: '$message\n\n— $ownerName',
      accentColor: priority == 'urgent'
          ? const Color(0xFFD32F2F)
          : priority == 'high'
              ? const Color(0xFFF57C00)
              : const Color(0xFF1F3D7A),
      actionLabel: 'Siap Laksanakan',
      onAction: () {
        AlarmService().stopAlarm();
        Navigator.of(context).pop();
        if (commandId.isNotEmpty) {
          _acknowledgeCommand(commandId);
        }
      },
    );
  }

  void _acknowledgeCommand(String commandId) {
    Future(() async {
      try {
        await ApiClient().dio.post('/commands/$commandId/acknowledge');
      } catch (_) {}
    });
  }

  void _showAlarmOverlay(String title, String message, {String? orderId, String? action}) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    showAlarmOverlay(
      context,
      title: title,
      message: message,
      orderId: orderId,
      onAction: action != null ? () {
        Navigator.of(context).pop();
        // Navigate based on action — extend as needed
      } : null,
      actionLabel: action != null ? 'Lihat' : null,
    );
  }

  void _showSnackbar(String title, String body, {bool isHigh = false}) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        duration: Duration(seconds: isHigh ? 6 : 3),
        backgroundColor: isHigh ? Colors.orange.shade800 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
