import 'notification_feedback_service.dart';

/// Watcher sederhana untuk detect jumlah notif berubah.
/// Dashboard panggil `check()` setiap refresh — kalau count naik, trigger audio+haptic.
///
/// Usage di State class:
/// ```
/// final _notifWatcher = NotificationWatcher();
///
/// Future<void> _loadData() async {
///   // ... fetch data
///   _notifWatcher.check(
///     newCount: _pendingCount + _anomalyCount,
///     severity: _anomalyCount > 0 ? NotificationSeverity.alarm : NotificationSeverity.normal,
///   );
/// }
/// ```
class NotificationWatcher {
  int? _previousCount;

  /// Cek jumlah notifikasi sekarang vs sebelumnya.
  /// Kalau ada tambahan (delta > 0), trigger feedback audio + haptic.
  /// Return true kalau ada perubahan positif (ada update baru).
  bool check({
    required int newCount,
    NotificationSeverity severity = NotificationSeverity.normal,
  }) {
    final previous = _previousCount;
    _previousCount = newCount;

    // Skip pertama kali (initial load) — jangan ping tanpa konteks
    if (previous == null) return false;

    if (newCount > previous) {
      NotificationFeedbackService.notify(severity);
      return true;
    }
    return false;
  }

  /// Reset — misal saat user logout.
  void reset() {
    _previousCount = null;
  }
}
