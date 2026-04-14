import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class BillingRepository {
  final ApiClient _apiClient;

  BillingRepository(this._apiClient);

  Future<Response> getOrderBilling(String orderId) async {
    return await _apiClient.dio.get('/orders/$orderId/billing');
  }

  Future<Response> addManualItem(String orderId, Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/so/orders/$orderId/billing-items', data: data);
  }

  Future<Response> getConsumables(String orderId) async {
    return await _apiClient.dio.get('/orders/$orderId/consumables');
  }

  Future<Response> addConsumables(String orderId, Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/orders/$orderId/consumables', data: data);
  }
}
