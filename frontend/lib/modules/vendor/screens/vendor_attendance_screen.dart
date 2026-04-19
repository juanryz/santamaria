import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class VendorAttendanceScreen extends StatefulWidget {
  final String orderId;
  const VendorAttendanceScreen({super.key, required this.orderId});

  @override
  State<VendorAttendanceScreen> createState() => _VendorAttendanceScreenState();
}

class _VendorAttendanceScreenState extends State<VendorAttendanceScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _attendances = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/orders/${widget.orderId}/attendances');
      if (res.data['success'] == true) {
        _attendances = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkIn(String id) async {
    try {
      await _api.dio.post('/vendor/attendances/$id/check-in');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in berhasil')));
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal melakukan check-in. Silakan coba lagi.';
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 500) {
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
  }

  Future<void> _checkOut(String id) async {
    try {
      await _api.dio.post('/vendor/attendances/$id/check-out');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-out berhasil')));
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal melakukan check-out. Silakan coba lagi.';
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 500) {
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
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'late': return Colors.orange;
      case 'absent': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Presensi', accentColor: AppColors.brandSecondary),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _attendances.isEmpty
                ? const Center(child: Text('Belum ada jadwal presensi'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _attendances.length,
                    itemBuilder: (_, i) {
                      final a = _attendances[i];
                      final status = a['status'] ?? 'scheduled';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(a['kegiatan'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    GlassStatusBadge(label: status, color: _statusColor(status)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${a['attendance_date'] ?? '-'} | Jam: ${a['scheduled_jam'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${a['user']?['name'] ?? '-'} (${a['role'] ?? '-'})', style: const TextStyle(fontSize: 12)),
                                if (a['arrived_at'] != null) Text('Hadir: ${a['arrived_at']}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                if (a['departed_at'] != null) Text('Pulang: ${a['departed_at']}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (status == 'scheduled')
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _checkIn(a['id']),
                                          icon: const Icon(Icons.login, size: 16),
                                          label: const Text('Check-In'),
                                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                        ),
                                      ),
                                    if (status == 'present' || status == 'late') ...[
                                      if (status == 'scheduled') const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _checkOut(a['id']),
                                          icon: const Icon(Icons.logout, size: 16),
                                          label: const Text('Check-Out'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
