import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class CoffinRepository {
  final ApiClient _apiClient;

  CoffinRepository(this._apiClient);

  Future<Response> getCoffinOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    return await _apiClient.dio.get('/gudang/coffin-orders', queryParameters: params);
  }

  Future<Response> createCoffinOrder(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/gudang/coffin-orders', data: data);
  }

  Future<Response> getCoffinOrder(String id) async {
    return await _apiClient.dio.get('/gudang/coffin-orders/$id');
  }

  Future<Response> updateStatus(String id, String status) async {
    return await _apiClient.dio.put('/gudang/coffin-orders/$id/status', data: {'status': status});
  }

  Future<Response> completeStage(String orderId, String stageId, {String? completedByName, String? notes}) async {
    final data = <String, dynamic>{};
    if (completedByName != null) data['completed_by_name'] = completedByName;
    if (notes != null) data['notes'] = notes;
    return await _apiClient.dio.put('/gudang/coffin-orders/$orderId/stages/$stageId', data: data);
  }

  Future<Response> submitQc(String id, List<Map<String, dynamic>> results, {String? qcNotes}) async {
    final data = <String, dynamic>{'results': results};
    if (qcNotes != null) data['qc_notes'] = qcNotes;
    return await _apiClient.dio.post('/gudang/coffin-orders/$id/qc', data: data);
  }
}
