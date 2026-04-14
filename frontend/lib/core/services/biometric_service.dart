import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric authentication service.
/// - iOS: Face ID / Touch ID
/// - Android: Fingerprint / Face Unlock
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _enabledKey = 'biometric_enabled';
  static const _tokenKey = 'biometric_auth_token';

  bool _isAvailable = false;
  bool _isEnabled = false;

  bool get isAvailable => _isAvailable;
  bool get isEnabled => _isEnabled;

  /// Initialize — check device capabilities.
  Future<void> init() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      _isAvailable = canCheck || isSupported;

      if (_isAvailable) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('Available biometrics: $biometrics');
      }

      final enabled = await _storage.read(key: _enabledKey);
      _isEnabled = enabled == 'true';

      debugPrint('Biometric: available=$_isAvailable, enabled=$_isEnabled');
    } catch (e) {
      debugPrint('Biometric init error: $e');
      _isAvailable = false;
    }
  }

  /// Authenticate using biometrics.
  /// Returns true if authenticated successfully.
  Future<bool> authenticate({String reason = 'Verifikasi identitas Anda'}) async {
    if (!_isAvailable || !_isEnabled) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.message}');
      return false;
    }
  }

  /// Enable biometric login for current user.
  /// Stores auth token so biometric can be used for re-login.
  Future<void> enable(String authToken) async {
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _tokenKey, value: authToken);
    _isEnabled = true;
  }

  /// Disable biometric login.
  Future<void> disable() async {
    await _storage.write(key: _enabledKey, value: 'false');
    await _storage.delete(key: _tokenKey);
    _isEnabled = false;
  }

  /// Get stored auth token (for biometric re-login).
  Future<String?> getStoredToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Get biometric type description for UI.
  String get biometricLabel {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Face ID / Touch ID';
    }
    return 'Fingerprint';
  }

  /// Get biometric icon for UI.
  String get biometricIcon {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'face_id'; // custom icon
    }
    return 'fingerprint';
  }
}
