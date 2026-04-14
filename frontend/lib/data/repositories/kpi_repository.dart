import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class KpiRepository {
  final ApiClient _apiClient;

  KpiRepository(this._apiClient);

  Future<Response> getMyKpi() async {
    return await _apiClient.dio.get('/my-kpi');
  }

  Future<Response> getMetrics({String? role}) async {
    final params = <String, dynamic>{};
    if (role != null) params['role'] = role;
    return await _apiClient.dio.get('/hrd/kpi/metrics', queryParameters: params);
  }

  Future<Response> getPeriods() async {
    return await _apiClient.dio.get('/hrd/kpi/periods');
  }

  Future<Response> getSummaries(String periodId, {String? role}) async {
    final params = <String, dynamic>{};
    if (role != null) params['role'] = role;
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/summaries', queryParameters: params);
  }

  Future<Response> getRankings(String periodId) async {
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/rankings');
  }

  Future<Response> getScores(String periodId, {String? userId}) async {
    final params = <String, dynamic>{};
    if (userId != null) params['user_id'] = userId;
    return await _apiClient.dio.get('/hrd/kpi/periods/$periodId/scores', queryParameters: params);
  }
}
