import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Periksa jaringan Anda.';
        case DioExceptionType.connectionError:
          return 'Tidak ada koneksi internet.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          final message = data is Map ? data['message'] as String? : null;
          switch (statusCode) {
            case 401:
              return message ?? 'Sesi berakhir. Silakan login kembali.';
            case 403:
              return message ?? 'Anda tidak memiliki akses.';
            case 404:
              return 'Data tidak ditemukan.';
            case 422:
              return message ?? 'Data tidak valid.';
            case 429:
              return 'Terlalu banyak percobaan. Coba lagi nanti.';
            case 500:
              return 'Terjadi kesalahan server. Coba lagi.';
            default:
              return message ?? 'Terjadi kesalahan.';
          }
        default:
          return 'Terjadi kesalahan. Coba lagi.';
      }
    }
    return 'Terjadi kesalahan tidak terduga.';
  }

  /// Get field-level validation errors from 422 response.
  static Map<String, String> getFieldErrors(dynamic error) {
    if (error is DioException && error.response?.statusCode == 422) {
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          return errors.map(
              (k, v) => MapEntry(k, (v as List).first.toString()));
        }
      }
    }
    return {};
  }

  /// Get specific login error message based on backend response.
  static String getLoginMessage(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message =
          (data is Map ? data['message'] as String? : null)?.toLowerCase() ??
              '';

      if (statusCode == 429) {
        return 'Terlalu banyak percobaan. Coba lagi dalam beberapa saat.';
      }
      if (statusCode == 403 &&
          (message.contains('inactive') || message.contains('nonaktif'))) {
        return 'Akun Anda dinonaktifkan. Hubungi admin.';
      }
      if (statusCode == 401) {
        if (message.contains('password') || message.contains('kata sandi')) {
          return 'Password salah. Coba lagi.';
        }
        if (message.contains('not found') ||
            message.contains('tidak ditemukan')) {
          return 'Akun tidak ditemukan.';
        }
      }
    }
    return 'Login gagal. Periksa email dan password Anda.';
  }

  /// Show error snackbar.
  static void showError(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(getMessage(error)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  /// Show success snackbar.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}
