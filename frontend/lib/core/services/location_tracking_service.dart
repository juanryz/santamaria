import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../constants/app_config.dart';

/// v1.35 — Background Location Tracking Service
///
/// Berjalan sebagai foreground service di Android dan background mode di iOS.
/// Karyawan harus menyetujui via [LocationConsentDialog] sebelum service ini aktif.
/// Mengirim koordinat ke backend setiap 30 detik.
class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  static const _channelId = 'santa_maria_location';
  static const _channelName = 'Pemantauan Lokasi';
  static const _notifId = 888;

  /// Inisialisasi dan jalankan background service.
  /// Harus dipanggil SETELAH user menyetujui consent.
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await _setupNotificationChannel();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Santa Maria',
        initialNotificationContent: 'Pemantauan lokasi aktif',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onBackgroundStart,
        onBackground: _onIosBackground,
      ),
    );

    await service.startService();
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  Future<bool> isRunning() async {
    return FlutterBackgroundService().isRunning();
  }

  Future<void> _setupNotificationChannel() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi aktif saat pemantauan lokasi berjalan',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
}

/// Entry point background isolate — harus top-level function.
@pragma('vm:entry-point')
void _onBackgroundStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Handler untuk stop dari UI
  service.on('stop').listen((_) => service.stopSelf());

  // Update notifikasi foreground
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    await service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'Santa Maria',
      content: 'Pemantauan lokasi aktif',
    );
  }

  // Kirim lokasi setiap 30 detik
  Timer.periodic(const Duration(seconds: 30), (_) async {
    await _sendLocation(service);
  });

  // Kirim langsung saat start
  await _sendLocation(service);
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Ambil GPS dan kirim ke backend
Future<void> _sendLocation(ServiceInstance service) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Baca token dari secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    await dio.post('/user/location', data: {
      'latitude':  position.latitude,
      'longitude': position.longitude,
      'accuracy':  position.accuracy,
      'speed':     position.speed >= 0 ? position.speed : null,
      'heading':   position.heading >= 0 ? position.heading : null,
      'altitude':  position.altitude,
      'is_moving': position.speed > 0.5,
    });
  } catch (_) {
    // Gagal silent — tidak mengganggu UX
  }
}
