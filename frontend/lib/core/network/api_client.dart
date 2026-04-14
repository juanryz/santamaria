import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle unauthorized access (logout)
          }
          if (e.response?.statusCode == 429) {
            final retryAfter = e.response?.headers.value('retry-after');
            final seconds = retryAfter != null ? int.tryParse(retryAfter) ?? 60 : 60;
            e = e.copyWith(
              error: 'Terlalu banyak permintaan. Coba lagi dalam $seconds detik.',
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
