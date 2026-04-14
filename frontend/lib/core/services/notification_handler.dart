import 'dart:convert';
import 'package:flutter/material.dart';
import '../../shared/widgets/glass_alarm_overlay.dart';

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

    switch (priority) {
      case 'ALARM':
      case 'VERY_HIGH':
        _showAlarmOverlay(title, body, orderId: orderId, action: action);
        break;
      case 'HIGH':
        _showSnackbar(title, body, isHigh: true);
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
    }
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
