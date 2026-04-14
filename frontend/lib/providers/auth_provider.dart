import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  Map<String, dynamic>? _user;
  bool _isLoading = false;

  AuthProvider(this._repository);

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> loginInternal(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.loginInternal(identifier, password);
      if (response.data['success']) {
        final token = response.data['data']['access_token'];
        _user = response.data['data']['user'];
        await _storage.write(key: 'auth_token', value: token);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerConsumer(String name, String phone, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.registerConsumer(name, phone, pin);
      if (response.data['success']) {
        final token = response.data['data']['access_token'];
        _user = response.data['data']['user'];
        await _storage.write(key: 'auth_token', value: token);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginConsumer(String phone, String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.loginConsumer(phone, pin);
      if (response.data['success']) {
        final token = response.data['data']['access_token'];
        _user = response.data['data']['user'];
        await _storage.write(key: 'auth_token', value: token);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore session from a stored token (biometric re-login).
  Future<void> restoreSession(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.write(key: 'auth_token', value: token);
      // Fetch user profile with the stored token
      final response = await _repository.getMe();
      if (response.data['success'] == true) {
        _user = response.data['data'];
      } else {
        throw Exception('Session expired');
      }
    } catch (e) {
      await _storage.delete(key: 'auth_token');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      _user = null;
      await _storage.delete(key: 'auth_token');
      notifyListeners();
    }
  }
}
