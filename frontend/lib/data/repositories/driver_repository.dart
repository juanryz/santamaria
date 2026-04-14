import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class DriverRepository {
  final ApiClient _apiClient;
  DriverRepository(this._apiClient);

  Future<Response> getAssignments() =>
      _apiClient.dio.get('/driver/orders');

  Future<Response> getOrderDetail(String id) =>
      _apiClient.dio.get('/driver/orders/$id');

  Future<Response> updateStatus(String id, String status) =>
      _apiClient.dio.put('/driver/orders/$id/status', data: {'status': status});

  Future<Response> sendLocation(double lat, double lng, {String? orderId}) =>
      _apiClient.dio.post('/driver/location', data: {
        'lat': lat,
        'lng': lng,
        'order_id': orderId,
        'recorded_at': DateTime.now().toIso8601String(),
      });
}
