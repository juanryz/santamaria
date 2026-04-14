import 'package:flutter/foundation.dart';

/// Anti-mock location detection — 6-layer validation per pedoman v1.17.
/// Layer 1: Flutter isFromMockProvider flag
/// Layer 2: Google Play Integrity API (production only)
/// Layer 3: Installed apps blacklist scan
/// Layer 4: Selfie capture with EXIF metadata
/// Layer 5: Backend geofence + velocity check (Haversine)
/// Layer 6: Device fingerprint consistency
class MockDetectionService {
  static final MockDetectionService instance = MockDetectionService._();
  MockDetectionService._();

  List<String> _blacklistedApps = [];

  /// Initialize with blacklist from backend.
  Future<void> init(List<String> blacklistedApps) async {
    _blacklistedApps = blacklistedApps;
  }

  /// Layer 1: Check if location is from mock provider.
  /// In production, use geolocator's `isMocked` field.
  bool checkMockProvider(bool isMocked) {
    if (isMocked) {
      debugPrint('MockDetection: Layer 1 FAILED — mock provider detected');
      return true;
    }
    return false;
  }

  /// Layer 3: Check if any blacklisted GPS spoofing apps are installed.
  /// In production, use installed_apps package to scan.
  Future<bool> checkBlacklistedApps() async {
    // Production implementation:
    // final apps = await InstalledApps.getInstalledApps();
    // for (final app in apps) {
    //   if (_blacklistedApps.contains(app.packageName)) return true;
    // }

    // Common mock location apps to detect:
    final commonMockApps = [
      'com.lexa.fakegps',
      'com.incorporateapps.fakegps.fre',
      'com.fakegps.mock',
      'com.blogspot.newapphorizons.fakegps',
      'com.evezzon.fakegps',
      ..._blacklistedApps,
    ];

    debugPrint('MockDetection: Layer 3 — scanning ${commonMockApps.length} known mock apps');
    return false; // placeholder — implement with installed_apps package
  }

  /// Layer 6: Device fingerprint — detect if multiple users use same device.
  /// Store device_id on backend; if same device_id for different user_id → flag.
  String getDeviceFingerprint() {
    // Production: use device_info_plus to get unique device identifier
    // final deviceInfo = await DeviceInfoPlugin().androidInfo;
    // return '${deviceInfo.id}_${deviceInfo.fingerprint}';

    return 'device_${DateTime.now().millisecondsSinceEpoch}'; // placeholder
  }

  /// Run all client-side checks. Returns map with results per layer.
  Future<Map<String, dynamic>> runAllChecks({
    required bool isMockedLocation,
    required double latitude,
    required double longitude,
  }) async {
    final results = <String, dynamic>{
      'layer1_mock_provider': checkMockProvider(isMockedLocation),
      'layer3_blacklisted_apps': await checkBlacklistedApps(),
      'layer6_device_fingerprint': getDeviceFingerprint(),
      'is_mock_detected': false,
    };

    results['is_mock_detected'] = results['layer1_mock_provider'] == true
        || results['layer3_blacklisted_apps'] == true;

    return results;
  }
}
