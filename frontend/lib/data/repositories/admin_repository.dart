import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _apiClient;
  AdminRepository(this._apiClient);

  Future<Response> getDashboard() =>
      _apiClient.dio.get('/admin/dashboard');

  Future<Response> getOrders() =>
      _apiClient.dio.get('/admin/orders');

  Future<Response> getOrderDetail(String id) =>
      _apiClient.dio.get('/admin/orders/$id');

  Future<Response> approveOrder(String id, Map<String, dynamic> data) =>
      _apiClient.dio.put('/admin/orders/$id/approve', data: data);

  Future<Response> updatePayment(String id, Map<String, dynamic> data) =>
      _apiClient.dio.put('/admin/orders/$id/payment', data: data);

  Future<Response> getAvailableDrivers(String scheduledAt) =>
      _apiClient.dio.get('/admin/drivers/available', queryParameters: {'scheduled_at': scheduledAt});

  Future<Response> getAvailableVehicles(String scheduledAt) =>
      _apiClient.dio.get('/admin/vehicles/available', queryParameters: {'scheduled_at': scheduledAt});
}
