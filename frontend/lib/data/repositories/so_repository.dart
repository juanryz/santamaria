import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class SORepository {
  final ApiClient _apiClient;
  SORepository(this._apiClient);

  Future<Response> getOrders() =>
      _apiClient.dio.get('/so/orders');

  Future<Response> getOrderDetail(String id) =>
      _apiClient.dio.get('/so/orders/$id');

  Future<Response> submitOrder(String id, Map<String, dynamic> data) =>
      _apiClient.dio.put('/so/orders/$id/submit', data: data);

  Future<Response> confirmOrder(String id, Map<String, dynamic> data) =>
      _apiClient.dio.put('/so/orders/$id/confirm', data: data);

  Future<Response> getPackages() =>
      _apiClient.dio.get('/so/packages');

  Future<Response> createOrder(Map<String, dynamic> data) =>
      _apiClient.dio.post('/so/orders', data: data);

  Future<Response> getAddOns() =>
      _apiClient.dio.get('/addons');

  Future<Response> addOrderAddOn(String orderId, String addonId) =>
      _apiClient.dio.post('/so/orders/$orderId/addons', data: {
        'add_on_service_id': addonId,
        'quantity': 1
      });

  Future<Response> deleteOrder(String id) =>
      _apiClient.dio.delete('/so/orders/$id');
}
