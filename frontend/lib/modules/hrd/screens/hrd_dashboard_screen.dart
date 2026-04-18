import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'hrd_violation_list_screen.dart';
import 'hrd_threshold_screen.dart';
import 'kpi_management_screen.dart';
import 'hrd_attendance_dashboard_screen.dart';
import 'hrd_shift_management_screen.dart';
import 'hrd_employee_list_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';
import 'hrd_payroll_screen.dart';
import 'hrd_salary_config_screen.dart';
import 'leaves_approval_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class HrdDashboardScreen extends StatefulWidget {
  const HrdDashboardScreen({super.key});

  @override
  State<HrdDashboardScreen> createState() => _HrdDashboardScreenState();
}

class _HrdDashboardScreenState extends State<HrdDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  static const _roleColor = AppColors.roleHrd;

  int _totalViolations = 0;
  int _pendingViolations = 0;
  int _criticalViolations = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/violations');
      if (res.data['success'] == true) {
        final list = List<dynamic>.from(res.data['data'] ?? []);
        _totalViolations = list.length;
        _pendingViolations = list.where((v) => v['status'] == 'pending').length;
        _criticalViolations = list.where((v) => v['severity'] == 'critical').length;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'HRD',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatRow(),
                  const SizedBox(height: 24),
                  _buildMenuList(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        _statCard('Total\nPelanggaran', _totalViolations, Icons.warning_amber, Colors.orange),
        const SizedBox(width: 12),
        _statCard('Belum\nDitangani', _pendingViolations, Icons.pending_actions, Colors.red),
        const SizedBox(width: 12),
        _statCard('Kritis', _criticalViolations, Icons.error, Colors.red.shade800),
      ],
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    final menus = [
      {'icon': Icons.campaign, 'label': 'Perintah dari Owner', 'screen': const EmployeeCommandScreen(roleColor: AppColors.roleHrd)},
      {'icon': Icons.badge_outlined, 'label': 'Manajemen Karyawan', 'screen': const HrdEmployeeListScreen()},
      {'icon': Icons.warning_amber, 'label': 'Daftar Pelanggaran', 'screen': const HrdViolationListScreen()},
      {'icon': Icons.tune, 'label': 'Pengaturan Threshold', 'screen': const HrdThresholdScreen()},
      {'icon': Icons.people, 'label': 'Presensi Karyawan', 'screen': const HrdAttendanceDashboardScreen()},
      {'icon': Icons.bar_chart, 'label': 'KPI Karyawan', 'screen': const KpiManagementScreen()},
      {'icon': Icons.schedule, 'label': 'Shift & Lokasi', 'screen': const HrdShiftManagementScreen()},
      {'icon': Icons.payments, 'label': 'Payroll', 'screen': const HrdPayrollScreen()},
      {'icon': Icons.monetization_on, 'label': 'Konfigurasi Gaji', 'screen': const HrdSalaryConfigScreen()},
      // v1.39 — Cuti & Izin
      {'icon': Icons.event_busy, 'label': 'Approval Cuti & Izin', 'screen': const LeavesApprovalScreen()},
      {'icon': Icons.event_available, 'label': 'Cuti Saya', 'screen': const MyLeavesScreen()},
    ];

    return Column(
      children: menus.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: Icon(m['icon'] as IconData, color: _roleColor),
              title: Text(m['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: m['screen'] != null
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => m['screen'] as Widget))
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
