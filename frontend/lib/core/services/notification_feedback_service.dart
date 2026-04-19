import 'package:flutter/services.dart';

/// Feedback visual + audio + haptic saat ada notification baru
/// detected by dashboard (tanpa FCM).
///
/// Pakai system sound + haptic built-in Flutter — tidak butuh package tambahan.
/// Cocok untuk in-foreground notification ping di elderly users.
///
/// Usage:
/// ```
/// NotificationFeedbackService.notify(NotificationSeverity.alarm);
/// ```
class NotificationFeedbackService {
  NotificationFeedbackService._();

  /// Ping saat ada update NORMAL (misal: 1 order baru).
  static Future<void> notifyNormal() async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  /// Ping untuk update HIGH priority (misal: order urgent).
  static Future<void> notifyHigh() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.mediumImpact();
  }

  /// Ping untuk ALARM critical (misal: anomali, pelanggaran).
  /// Haptic lebih kuat, double ping.
  static Future<void> notifyAlarm() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
  }

  /// Trigger by severity enum.
  static Future<void> notify(NotificationSeverity severity) {
    return switch (severity) {
      NotificationSeverity.alarm => notifyAlarm(),
      NotificationSeverity.high => notifyHigh(),
      NotificationSeverity.normal => notifyNormal(),
    };
  }

  /// Feedback saat user tap tombol action penting (confirm, submit).
  static Future<void> tapImportant() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback saat aksi sukses.
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  /// Feedback saat aksi gagal / error.
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }
}

enum NotificationSeverity { normal, high, alarm }
