import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class HrdRepository {
  final ApiClient _apiClient;

  HrdRepository(this._apiClient);

  // Violations
  Future<Response> getViolations({String? status, String? type}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    return await _apiClient.dio.get('/hrd/violations', queryParameters: params);
  }

  Future<Response> getViolation(String id) async {
    return await _apiClient.dio.get('/hrd/violations/$id');
  }

  Future<Response> acknowledgeViolation(String id) async {
    return await _apiClient.dio.put('/hrd/violations/$id/acknowledge');
  }

  Future<Response> resolveViolation(String id, {String? notes}) async {
    return await _apiClient.dio.put('/hrd/violations/$id/resolve', data: {'notes': notes});
  }

  Future<Response> escalateViolation(String id, {String? notes}) async {
    return await _apiClient.dio.put('/hrd/violations/$id/escalate', data: {'notes': notes});
  }

  Future<Response> getMonthlyReport() async {
    return await _apiClient.dio.get('/hrd/violations/monthly-report');
  }

  Future<Response> getUserHistory(String userId) async {
    return await _apiClient.dio.get('/hrd/violations/by-user/$userId');
  }

  // Thresholds
  Future<Response> getThresholds() async {
    return await _apiClient.dio.get('/hrd/thresholds');
  }

  Future<Response> updateThreshold(String key, String value) async {
    return await _apiClient.dio.put('/hrd/thresholds/$key', data: {'value': value});
  }

  // Attendance
  Future<Response> getAttendances({String? status, String? role}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (role != null) params['role'] = role;
    return await _apiClient.dio.get('/hrd/attendances', queryParameters: params);
  }

  // KPI
  Future<Response> getKpiMetrics({String? role}) async {
    final params = <String, dynamic>{};
    if (role != null) params['role'] = role;
    return await _apiClient.dio.get('/hrd/kpi/metrics', queryParameters: params);
  }

  Future<Response> createKpiMetric(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/hrd/kpi/metrics', data: data);
  }

  Future<Response> updateKpiMetric(String id, Map<String, dynamic> data) async {
    return await _apiClient.dio.put('/hrd/kpi/metrics/$id', data: data);
  }

  Future<Response> getKpiPeriods() async {
    return await _apiClient.dio.get('/hrd/kpi/periods');
  }

  Future<Response> getKpiScores(String periodId, {String? userId}) async {
    final params = <String, dynamic>{};
    if (userId != null) params['user_id'] = userId;
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/scores', queryParameters: params);
  }

  Future<Response> getKpiSummaries(String periodId, {String? role}) async {
    final params = <String, dynamic>{};
    if (role != null) params['role'] = role;
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/summaries', queryParameters: params);
  }

  Future<Response> getKpiRankings(String periodId) async {
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/rankings');
  }
}
