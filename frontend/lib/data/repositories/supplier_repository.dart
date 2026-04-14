import 'dart:io';

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class SupplierRepository {
  final ApiClient _apiClient;

  SupplierRepository(this._apiClient);

  Future<Response> getAvailablePurchaseOrders() async {
    return await _apiClient.dio.get('/vendor/purchase-orders');
  }

  Future<Response> getPurchaseOrderDetail(String id) async {
    return await _apiClient.dio.get('/vendor/purchase-orders/$id');
  }

  Future<Response> getSupplierQuotes() async {
    return await _apiClient.dio.get('/vendor/supplier-quotes');
  }

  Future<Response> getSupplierQuoteDetail(String id) async {
    return await _apiClient.dio.get('/vendor/supplier-quotes/$id');
  }

  Future<Response> createSupplierQuote(
      String purchaseOrderId, double quotePrice, String? quoteNotes) async {
    return await _apiClient.dio.post('/vendor/supplier-quotes', data: {
      'purchase_order_id': purchaseOrderId,
      'quote_price': quotePrice,
      'quote_notes': quoteNotes,
    });
  }

  /// Upload or replace product photo for an existing quote.
  /// QA 4.3: POST /vendor/supplier-quotes/{id}/photo
  Future<Response> uploadQuotePhoto(String quoteId, File photo) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
    });
    return await _apiClient.dio.post(
      '/vendor/supplier-quotes/$quoteId/photo',
      data: formData,
    );
  }

  Future<Response> getProfile() async {
    return await _apiClient.dio.get('/auth/me');
  }
}
