import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class PurchasingRepository {
  final ApiClient _apiClient;

  PurchasingRepository(this._apiClient);

  // Consumer Payment Verification
  Future<Response> getPendingPayments() async {
    return await _apiClient.dio.get('/finance/consumer-payments/pending');
  }

  Future<Response> verifyPayment(String orderId) async {
    return await _apiClient.dio.put('/finance/consumer-payments/$orderId/verify');
  }

  Future<Response> rejectPayment(String orderId, String reason) async {
    return await _apiClient.dio.put('/finance/consumer-payments/$orderId/reject', data: {'reason': reason});
  }

  // Supplier Transactions
  Future<Response> getSupplierTransactions() async {
    return await _apiClient.dio.get('/finance/supplier-transactions');
  }

  Future<Response> paySupplier(String transactionId, Map<String, dynamic> data) async {
    return await _apiClient.dio.put('/finance/supplier-transactions/$transactionId/pay', data: data);
  }

  // Field Team Payments
  Future<Response> getFieldTeamPending() async {
    return await _apiClient.dio.get('/finance/field-team/pending');
  }

  Future<Response> payFieldTeam(String paymentId, Map<String, dynamic> data) async {
    return await _apiClient.dio.put('/finance/field-team/$paymentId/pay', data: data);
  }

  // Procurement Approvals
  Future<Response> getProcurementPending() async {
    return await _apiClient.dio.get('/finance/procurement-requests/pending');
  }

  Future<Response> approveProcurement(String id) async {
    return await _apiClient.dio.put('/finance/procurement-requests/$id/approve');
  }

  Future<Response> rejectProcurement(String id, String reason) async {
    return await _apiClient.dio.put('/finance/procurement-requests/$id/reject', data: {'reason': reason});
  }

  // Billing
  Future<Response> getOrderBilling(String orderId) async {
    return await _apiClient.dio.get('/orders/$orderId/billing');
  }

  Future<Response> updateBillingItem(String orderId, String itemId, Map<String, dynamic> data) async {
    return await _apiClient.dio.put('/purchasing/orders/$orderId/billing-items/$itemId', data: data);
  }

  Future<Response> getBillingTotal(String orderId) async {
    return await _apiClient.dio.get('/purchasing/orders/$orderId/billing/total');
  }
}
