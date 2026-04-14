import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class OwnerRepository {
  final ApiClient _apiClient;
  OwnerRepository(this._apiClient);

  Future<Response> getDashboard() =>
      _apiClient.dio.get('/owner/dashboard');

  Future<Response> getOrders({int page = 1}) =>
      _apiClient.dio.get('/owner/orders', queryParameters: {'page': page});

  Future<Response> getDailyReports() =>
      _apiClient.dio.get('/owner/reports/daily');

  Future<Response> getAnomalies() =>
      _apiClient.dio.get('/owner/purchase-orders/anomalies');

  Future<Response> overridePO(String id, String decision, String notes) =>
      _apiClient.dio.put('/owner/purchase-orders/$id/override', data: {
        'decision': decision,
        'notes': notes,
      });
}
