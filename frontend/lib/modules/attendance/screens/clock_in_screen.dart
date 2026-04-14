import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Daily attendance clock-in screen with geofence indicator.
class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isClockedIn = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _todayData;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/attendance/me/today');
      if (res.data['success'] == true) {
        _todayData = Map<String, dynamic>.from(res.data['data']);
        _isClockedIn = _todayData?['attendance']?['clock_in_at'] != null;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _clockIn() async {
    setState(() => _isSubmitting = true);
    try {
      // In production: use geolocator to get real position
      // For now, use dummy coordinates
      final res = await _api.dio.post('/attendance/clock-in', data: {
        'latitude': -6.9666,
        'longitude': 110.4196,
        'is_mock_provider': false,
      });

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Clock-in berhasil')));
        _loadToday();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal melakukan clock-in. Silakan coba lagi.';
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
          if (statusCode == 403) {
            msg = 'Lokasi palsu terdeteksi!';
          } else if (statusCode == 401) {
            msg = 'Sesi Anda telah berakhir. Silakan login ulang.';
          } else if (statusCode == 422 && serverMsg != null) {
            msg = serverMsg;
          } else if (statusCode == 500) {
            msg = 'Terjadi gangguan pada server. Silakan coba beberapa saat lagi.';
          } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
            msg = 'Koneksi timeout. Periksa jaringan Anda dan coba lagi.';
          } else if (e.type == DioExceptionType.connectionError) {
            msg = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _clockOut() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await _api.dio.post('/attendance/clock-out', data: {
        'latitude': -6.9666,
        'longitude': 110.4196,
      });

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Clock-out berhasil')));
        _loadToday();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal melakukan clock-out. Silakan coba lagi.';
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) {
            msg = 'Sesi Anda telah berakhir. Silakan login ulang.';
          } else if (statusCode == 500) {
            msg = 'Terjadi gangguan pada server. Silakan coba beberapa saat lagi.';
          } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
            msg = 'Koneksi timeout. Periksa jaringan Anda dan coba lagi.';
          } else if (e.type == DioExceptionType.connectionError) {
            msg = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final attendance = _todayData?['attendance'];
    final assignment = _todayData?['assignment'];
    final hasClockedOut = attendance?['clock_out_at'] != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Presensi Harian', accentColor: AppColors.brandPrimary),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadToday,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Today's status card
                  GlassWidget(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            hasClockedOut ? Icons.check_circle : _isClockedIn ? Icons.timelapse : Icons.schedule,
                            size: 64,
                            color: hasClockedOut ? Colors.green : _isClockedIn ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hasClockedOut ? 'Sudah Pulang' : _isClockedIn ? 'Sedang Bekerja' : 'Belum Hadir',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hasClockedOut ? Colors.green : _isClockedIn ? Colors.blue : Colors.grey,
                            ),
                          ),
                          if (attendance?['status'] == 'late')
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Terlambat', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 12),
                          if (attendance?['clock_in_at'] != null)
                            Text('Masuk: ${attendance!['clock_in_at']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          if (attendance?['clock_out_at'] != null)
                            Text('Pulang: ${attendance!['clock_out_at']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          if (attendance?['work_hours'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Durasi: ${attendance!['work_hours']} jam', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shift info
                  if (assignment != null)
                    GlassWidget(
                      borderRadius: 14,
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: AppColors.brandPrimary),
                        title: Text(assignment['shift']?['shift_name'] ?? 'Shift', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${assignment['shift']?['start_time'] ?? ''} - ${assignment['shift']?['end_time'] ?? ''}\n${assignment['location']?['name'] ?? ''}'),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Clock in/out button
                  if (!hasClockedOut)
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : (_isClockedIn ? _clockOut : _clockIn),
                      icon: Icon(_isClockedIn ? Icons.logout : Icons.login),
                      label: Text(
                        _isClockedIn ? 'Clock Out' : 'Clock In',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isClockedIn ? Colors.orange : Colors.green,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
