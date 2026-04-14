import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class GudangRepository {
  final ApiClient _apiClient;

  GudangRepository(this._apiClient);

  Future<Response> getPurchaseOrders() async {
    return await _apiClient.dio.get('/gudang/purchase-orders');
  }

  Future<Response> getPurchaseOrderDetail(String id) async {
    return await _apiClient.dio.get('/gudang/purchase-orders/$id');
  }

  Future<Response> createPurchaseOrder({
    required String itemName,
    required int quantity,
    required String unit,
    required double proposedPrice,
    String? supplierName,
    String? orderId,
  }) async {
    return await _apiClient.dio.post('/gudang/purchase-orders', data: {
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'proposed_price': proposedPrice,
      if (supplierName != null && supplierName.isNotEmpty) 'supplier_name': supplierName,
      'order_id': ?orderId,
    });
  }

  Future<Response> acceptQuote(String quoteId) async {
    return await _apiClient.dio.put('/gudang/supplier-quotes/$quoteId/accept');
  }

  Future<Response> rejectQuote(String quoteId) async {
    return await _apiClient.dio.put('/gudang/supplier-quotes/$quoteId/reject');
  }
}
