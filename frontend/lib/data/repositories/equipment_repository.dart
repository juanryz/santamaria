import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class EquipmentRepository {
  final ApiClient _apiClient;

  EquipmentRepository(this._apiClient);

  Future<Response> getMasterEquipment() async {
    return await _apiClient.dio.get('/gudang/equipment-master');
  }

  Future<Response> getOrderEquipment(String orderId) async {
    return await _apiClient.dio.get('/gudang/orders/$orderId/equipment');
  }

  Future<Response> prepareEquipment(String orderId, List<Map<String, dynamic>> items) async {
    return await _apiClient.dio.post('/gudang/orders/$orderId/equipment', data: {'items': items});
  }

  Future<Response> sendItem(String orderId, String itemId, {int? qtySent}) async {
    return await _apiClient.dio.put('/gudang/orders/$orderId/equipment/$itemId/send',
        data: qtySent != null ? {'qty_sent': qtySent} : null);
  }

  Future<Response> returnItem(String orderId, String itemId, {required int qtyReturned, String? returnedByName}) async {
    final data = <String, dynamic>{'qty_returned': qtyReturned};
    if (returnedByName != null) data['returned_by_family_name'] = returnedByName;
    return await _apiClient.dio.put('/gudang/orders/$orderId/equipment/$itemId/return', data: data);
  }

  Future<Response> getMissingEquipment() async {
    return await _apiClient.dio.get('/gudang/equipment/missing');
  }

  // Loans
  Future<Response> getLoans() async {
    return await _apiClient.dio.get('/gudang/equipment-loans');
  }

  Future<Response> createLoan(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/gudang/equipment-loans', data: data);
  }

  Future<Response> getLoan(String id) async {
    return await _apiClient.dio.get('/gudang/equipment-loans/$id');
  }

  Future<Response> updateLoanStatus(String id, String status) async {
    return await _apiClient.dio.put('/gudang/equipment-loans/$id/status', data: {'status': status});
  }
}
