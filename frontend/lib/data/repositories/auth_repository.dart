import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Response> registerConsumer(String name, String phone, String pin) async {
    return await _apiClient.dio.post('/auth/register-consumer', data: {
      'name': name,
      'phone': phone,
      'pin': pin,
    });
  }

  Future<Response> loginConsumer(String phone, String pin) async {
    return await _apiClient.dio.post('/auth/login-consumer', data: {
      'phone': phone,
      'pin': pin,
    });
  }

  Future<Response> loginInternal(String identifier, String password) async {
    return await _apiClient.dio.post('/auth/login-internal', data: {
      'identifier': identifier,
      'password': password,
    });
  }

  Future<Response> getMe() async {
    return await _apiClient.dio.get('/auth/me');
  }

  Future<Response> logout() async {
    return await _apiClient.dio.post('/auth/logout');
  }
}
