import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  // Consumer
  Future<Response> getConsumerOrders() async {
    return await _apiClient.dio.get('/consumer/orders');
  }

  // Service Officer
  Future<Response> getPendingOrders() async {
    return await _apiClient.dio.get('/so/orders');
  }

  // Admin
  Future<Response> getAdminDashboard() async {
    return await _apiClient.dio.get('/admin/dashboard');
  }

  // Driver
  Future<Response> getDriverAssignments() async {
    // Note: Reusing generic index or specific driver endpoint logic
    return await _apiClient.dio.get('/admin/orders'); // Simplified for now
  }

  Future<Response> createOrder(Map<String, dynamic> orderData) async {
    return await _apiClient.dio.post('/so/orders', data: orderData);
  }

  Future<Response> updateDriverLocation(double lat, double lng, {String? orderId}) async {
    return await _apiClient.dio.post('/driver/location', data: {
      'lat': lat,
      'lng': lng,
      'recorded_at': DateTime.now().toIso8601String(),
      'order_id': ?orderId,
    });
  }
}
