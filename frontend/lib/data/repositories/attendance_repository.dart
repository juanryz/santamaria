import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository(this._apiClient);

  Future<Response> getOrderAttendances(String orderId) async {
    return await _apiClient.dio.get('/orders/$orderId/attendances');
  }

  Future<Response> checkIn(String attendanceId) async {
    return await _apiClient.dio.post('/vendor/attendances/$attendanceId/check-in');
  }

  Future<Response> checkOut(String attendanceId) async {
    return await _apiClient.dio.post('/vendor/attendances/$attendanceId/check-out');
  }

  Future<Response> confirm(String attendanceId) async {
    return await _apiClient.dio.put('/so/attendances/$attendanceId/confirm');
  }
}
