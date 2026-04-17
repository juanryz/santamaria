import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../network/api_client.dart';

/// Data hasil foto + geofencing
class GeoPhoto {
  final File file;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final DateTime takenAt;
  final String deviceId;

  GeoPhoto({
    required this.file,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    required this.takenAt,
    required this.deviceId,
  });

  /// Convert ke MultipartFile untuk upload
  Future<MultipartFile> toMultipart({String fieldName = 'photo'}) async {
    return MultipartFile.fromFile(
      file.path,
      filename: '${takenAt.millisecondsSinceEpoch}.jpg',
    );
  }

  /// Convert ke FormData fields (tanpa file)
  Map<String, dynamic> toMetadata() => {
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    'accuracy_meters': accuracy?.toString() ?? '',
    'altitude': altitude?.toString() ?? '',
    'taken_at': takenAt.toIso8601String(),
    'device_id': deviceId,
  };
}

/// Service untuk ambil foto dari kamera + lokasi GPS secara bersamaan.
/// Dipakai di SEMUA titik yang butuh bukti foto + geofencing.
class GeoPhotoService {
  static final GeoPhotoService _instance = GeoPhotoService._();
  static GeoPhotoService get instance => _instance;
  GeoPhotoService._();

  final ImagePicker _picker = ImagePicker();

  /// Ambil foto dari kamera + lokasi GPS.
  /// Returns null jika user cancel atau lokasi tidak tersedia.
  /// [source] default kamera, bisa diubah ke CameraDevice.front untuk selfie.
  Future<GeoPhoto?> capture({
    CameraDevice preferredCamera = CameraDevice.rear,
    int maxWidth = 1280,
    int maxHeight = 1280,
    int imageQuality = 80,
  }) async {
    // 1. Cek permission lokasi
    final locationPermission = await _ensureLocationPermission();
    if (!locationPermission) return null;

    // 2. Ambil foto dari kamera (BUKAN galeri)
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: preferredCamera,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: imageQuality,
    );
    if (photo == null) return null;

    // 3. Ambil lokasi GPS saat ini
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // 4. Device ID
    final deviceId = await _getDeviceId();

    return GeoPhoto(
      file: File(photo.path),
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      takenAt: DateTime.now(),
      deviceId: deviceId,
    );
  }

  /// Ambil foto selfie (kamera depan) + lokasi
  Future<GeoPhoto?> captureSelfie() => capture(
    preferredCamera: CameraDevice.front,
    maxWidth: 640,
    maxHeight: 640,
    imageQuality: 70,
  );

  /// Upload foto + metadata ke backend
  Future<Map<String, dynamic>?> uploadEvidence({
    required GeoPhoto geoPhoto,
    required String context,
    String? orderId,
    String? referenceType,
    String? referenceId,
    String? notes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await geoPhoto.toMultipart(),
        'context': context,
        'order_id': ?orderId,
        'reference_type': ?referenceType,
        'reference_id': ?referenceId,
        'notes': ?notes,
        ...geoPhoto.toMetadata(),
      });

      final response = await ApiClient().dio.post(
        '${AppConfig.baseUrl}/photo-evidences',
        data: formData,
      );

      return response.data['data'];
    } catch (e) {
      debugPrint('GeoPhotoService upload error: $e');
      return null;
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<String> _getDeviceId() async {
    // Simple device ID — bisa diganti dengan device_info_plus jika perlu
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}
