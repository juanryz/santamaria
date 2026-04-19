import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/dynamic_status_badge.dart';

class HrdAttendanceDashboardScreen extends StatefulWidget {
  const HrdAttendanceDashboardScreen({super.key});

  @override
  State<HrdAttendanceDashboardScreen> createState() => _HrdAttendanceDashboardScreenState();
}

class _HrdAttendanceDashboardScreenState extends State<HrdAttendanceDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _attendances = [];
  static const _roleColor = AppColors.roleHrd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/attendances');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _attendances = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendances.where((a) => a['status'] == 'present').length;
    final lateCount = _attendances.where((a) => a['status'] == 'late').length;
    final absentCount = _attendances.where((a) => a['status'] == 'absent' || a['status'] == 'scheduled').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Presensi Karyawan', accentColor: _roleColor),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary row
                  Row(
                    children: [
                      _statCard('Hadir', presentCount, Icons.check_circle, Colors.green),
                      const SizedBox(width: 10),
                      _statCard('Telat', lateCount, Icons.schedule, Colors.orange),
                      const SizedBox(width: 10),
                      _statCard('Belum', absentCount, Icons.cancel, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._attendances.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassWidget(
                      borderRadius: 12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(a['status'] ?? '').withValues(alpha: 0.15),
                          child: Text((a['user']?['name'] ?? '?')[0], style: TextStyle(color: _statusColor(a['status'] ?? ''))),
                        ),
                        title: Text(a['user']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${a['role'] ?? '-'} | ${a['kegiatan'] ?? '-'}', style: const TextStyle(fontSize: 13)),
                        trailing: DynamicStatusBadge(enumGroup: 'attendance_status', value: a['status'] ?? ''),
                      ),
                    ),
                  )),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'present': return Colors.green;
      case 'late': return Colors.orange;
      case 'absent': return Colors.red;
      default: return Colors.grey;
    }
  }
}
