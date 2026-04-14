import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/dynamic_status_badge.dart';

/// My attendance history with monthly summary.
class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _attendances = [];
  Map<String, dynamic> _summary = {};
  final String _selectedMonth = DateTime.now().toString().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/attendance/me', queryParameters: {'month': _selectedMonth});
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _attendances = List<dynamic>.from(data['attendances'] ?? []);
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'late': return Colors.orange;
      case 'absent': return Colors.red;
      case 'early_leave': return Colors.amber;
      case 'leave': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Riwayat Presensi', accentColor: AppColors.brandPrimary),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary
                  GlassWidget(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bulan: $_selectedMonth', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _summaryChip('Hadir', _summary['present'] ?? 0, Colors.green),
                              _summaryChip('Telat', _summary['late'] ?? 0, Colors.orange),
                              _summaryChip('Absen', _summary['absent'] ?? 0, Colors.red),
                              _summaryChip('Pulang\nAwal', _summary['early_leave'] ?? 0, Colors.amber),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(child: Text('Rata-rata kerja: ${_summary['avg_work_hours'] ?? '-'} jam', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List
                  ..._attendances.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassWidget(
                          borderRadius: 12,
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor(a['status'] ?? '').withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  (a['attendance_date'] ?? '').toString().split('-').last,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(a['status'] ?? '')),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(a['attendance_date'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 8),
                                DynamicStatusBadge(enumGroup: 'attendance_status', value: a['status'] ?? ''),
                              ],
                            ),
                            subtitle: Text(
                              'Masuk: ${_timeOnly(a['clock_in_at'])} | Pulang: ${_timeOnly(a['clock_out_at'])} | ${a['work_hours'] ?? '-'} jam',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _timeOnly(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }
}
