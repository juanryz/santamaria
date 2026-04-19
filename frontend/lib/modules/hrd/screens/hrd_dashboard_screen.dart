import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_feedback_service.dart';
import '../../../core/services/notification_watcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/role_dashboard_header.dart';
import '../../../shared/widgets/senior_menu_grid.dart';
import 'hrd_violation_list_screen.dart';
import 'hrd_threshold_screen.dart';
import 'kpi_management_screen.dart';
import 'hrd_attendance_dashboard_screen.dart';
import 'hrd_shift_management_screen.dart';
import 'hrd_employee_list_screen.dart';
import 'hrd_payroll_screen.dart';
import 'hrd_salary_config_screen.dart';
import 'leaves_approval_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

/// HRD Dashboard — pattern seragam senior-friendly.
class HrdDashboardScreen extends StatefulWidget {
  const HrdDashboardScreen({super.key});

  @override
  State<HrdDashboardScreen> createState() => _HrdDashboardScreenState();
}

class _HrdDashboardScreenState extends State<HrdDashboardScreen> {
  final _api = ApiClient();
  final _notifWatcher = NotificationWatcher();
  int _pendingViolations = 0;
  int _pendingLeaves = 0;
  int _totalEmployees = 0;
  bool _isLoading = true;

  static const _roleColor = AppColors.roleHrd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final violations = await _api.dio.get('/hrd/violations?status=pending')
          .catchError((_) => null as dynamic);
      final leaves = await _api.dio.get('/hrd/leaves?status=requested')
          .catchError((_) => null as dynamic);
      final employees = await _api.dio.get('/hrd/employees')
          .catchError((_) => null as dynamic);

      if (violations != null && violations.data is Map && violations.data['success'] == true) {
        _pendingViolations = (violations.data['data'] as List?)?.length ?? 0;
      }
      if (leaves != null && leaves.data is Map && leaves.data['success'] == true) {
        _pendingLeaves = (leaves.data['data'] as List?)?.length ?? 0;
      }
      if (employees != null && employees.data is Map && employees.data['success'] == true) {
        _totalEmployees = (employees.data['data'] as List?)?.length ?? 0;
      }
      _notifWatcher.check(
        newCount: _pendingViolations + _pendingLeaves,
        severity: _pendingViolations > 0
            ? NotificationSeverity.alarm
            : NotificationSeverity.high,
      );
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DashboardNotification> _buildNotifications() {
    final list = <DashboardNotification>[];
    if (_pendingViolations > 0) {
      list.add(DashboardNotification(
        icon: Icons.gavel_rounded,
        title: 'Pelanggaran Baru',
        message: '$_pendingViolations pelanggaran perlu ditindaklanjuti',
        color: AppColors.statusDanger,
      ));
    }
    if (_pendingLeaves > 0) {
      list.add(DashboardNotification(
        icon: Icons.beach_access_rounded,
        title: 'Pengajuan Cuti',
        message: '$_pendingLeaves cuti menunggu approval',
        color: AppColors.statusWarning,
      ));
    }
    return list;
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = (user?['name'] as String?) ?? 'HRD';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RoleDashboardHeader(
                            roleLabel: 'HRD',
                            roleColor: _roleColor,
                            greeting: _getGreeting(),
                            userName: userName,
                            notifications: _buildNotifications(),
                            badges: [
                              if (_pendingViolations > 0)
                                HeaderBadge(
                                  label: '$_pendingViolations Pelanggaran',
                                  color: AppColors.statusDanger,
                                  icon: Icons.gavel_rounded,
                                ),
                              if (_pendingLeaves > 0)
                                HeaderBadge(
                                  label: '$_pendingLeaves Cuti',
                                  color: AppColors.statusWarning,
                                  icon: Icons.beach_access_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Karyawan',
                                    value: _totalEmployees.toString(),
                                    icon: Icons.people_rounded,
                                    color: _roleColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Pelanggaran',
                                    value: _pendingViolations.toString(),
                                    icon: Icons.gavel_rounded,
                                    color: AppColors.statusDanger,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Cuti Pending',
                                    value: _pendingLeaves.toString(),
                                    icon: Icons.beach_access_rounded,
                                    color: AppColors.statusWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Menu Utama', Icons.dashboard_rounded),
                          SeniorMenuGrid(
                            columns: 3,
                            items: _buildMenu(),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: _roleColor, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<SeniorMenuItem> _buildMenu() {
    return [
      SeniorMenuItem(
        icon: Icons.people_rounded,
        label: 'Karyawan',
        subtitle: '$_totalEmployees orang',
        color: _roleColor,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdEmployeeListScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.gavel_rounded,
        label: 'Pelanggaran',
        subtitle: 'Daftar pelanggaran',
        color: AppColors.statusDanger,
        badge: _pendingViolations > 0 ? _pendingViolations : null,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdViolationListScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.beach_access_rounded,
        label: 'Cuti Masuk',
        subtitle: 'Approval cuti',
        color: AppColors.statusWarning,
        badge: _pendingLeaves > 0 ? _pendingLeaves : null,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LeavesApprovalScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.fingerprint_rounded,
        label: 'Presensi',
        subtitle: 'Attendance',
        color: AppColors.brandPrimary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdAttendanceDashboardScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.schedule_rounded,
        label: 'Shift',
        subtitle: 'Kelola shift',
        color: AppColors.statusInfo,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdShiftManagementScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.leaderboard_rounded,
        label: 'KPI',
        subtitle: 'Kinerja tim',
        color: AppColors.brandAccent,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const KpiManagementScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.payments_rounded,
        label: 'Payroll',
        subtitle: 'Gaji bulanan',
        color: AppColors.statusSuccess,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdPayrollScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Gaji Pokok',
        subtitle: 'Konfigurasi',
        color: AppColors.brandSecondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdSalaryConfigScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.tune_rounded,
        label: 'Threshold',
        subtitle: 'Batas sistem',
        color: AppColors.textSecondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HrdThresholdScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Perintah',
        subtitle: 'Dari Owner',
        color: AppColors.roleOwner,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const EmployeeCommandScreen(roleColor: AppColors.roleHrd))),
      ),
      SeniorMenuItem(
        icon: Icons.event_note_rounded,
        label: 'Cuti Saya',
        subtitle: 'Ajukan cuti',
        color: AppColors.rolePemukaAgama,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyLeavesScreen())),
      ),
    ];
  }
}
