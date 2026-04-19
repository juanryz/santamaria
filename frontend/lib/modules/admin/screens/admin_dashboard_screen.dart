import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_feedback_service.dart';
import '../../../core/services/notification_watcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/role_dashboard_header.dart';
import '../../../shared/widgets/senior_menu_grid.dart';
import 'admin_order_list_screen.dart';
import 'admin_package_management_screen.dart';
import 'admin_fleet_management_screen.dart';
import 'admin_master_data_screen.dart';
import 'admin_documentation_screen.dart';
import 'cctv_management_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';

/// Admin Dashboard — pattern seragam senior-friendly.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminRepository _repo;
  final _notifWatcher = NotificationWatcher();
  Map<String, dynamic> _stats = {};
  int _pendingOrders = 0;
  int _activeOrders = 0;
  bool _isLoading = true;

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _repo = AdminRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getDashboard();
      if (res.data['success'] == true) {
        _stats = Map<String, dynamic>.from(res.data['data'] ?? {});
        _pendingOrders = (_stats['pending_orders'] as int?) ?? 0;
        _activeOrders = (_stats['active_orders'] as int?) ?? 0;
      }
      _notifWatcher.check(
        newCount: _pendingOrders,
        severity: NotificationSeverity.high,
      );
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DashboardNotification> _buildNotifications() {
    final list = <DashboardNotification>[];
    if (_pendingOrders > 0) {
      list.add(DashboardNotification(
        icon: Icons.local_shipping_rounded,
        title: 'Perlu Armada',
        message: '$_pendingOrders order menunggu armada',
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
    final userName = (user?['name'] as String?) ?? 'Admin';

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
                            roleLabel: 'Admin',
                            roleColor: _roleColor,
                            greeting: _getGreeting(),
                            userName: userName,
                            notifications: _buildNotifications(),
                            badges: [
                              if (_pendingOrders > 0)
                                HeaderBadge(
                                  label: '$_pendingOrders Perlu Armada',
                                  color: AppColors.statusWarning,
                                  icon: Icons.local_shipping_rounded,
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
                                    label: 'Perlu Armada',
                                    value: _pendingOrders.toString(),
                                    icon: Icons.local_shipping_rounded,
                                    color: AppColors.statusWarning,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Sedang Proses',
                                    value: _activeOrders.toString(),
                                    icon: Icons.autorenew_rounded,
                                    color: _roleColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Total Order',
                                    value: '${_stats['total_orders'] ?? 0}',
                                    icon: Icons.list_alt_rounded,
                                    color: AppColors.brandPrimary,
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
        icon: Icons.receipt_long_rounded,
        label: 'Order',
        subtitle: 'Daftar order',
        color: _roleColor,
        badge: _pendingOrders > 0 ? _pendingOrders : null,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminOrderListScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.inventory_2_rounded,
        label: 'Paket',
        subtitle: 'Kelola paket',
        color: AppColors.brandPrimary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminPackageManagementScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.local_shipping_rounded,
        label: 'Armada',
        subtitle: 'Kendaraan',
        color: AppColors.roleDriver,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminFleetManagementScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.settings_rounded,
        label: 'Master Data',
        subtitle: 'Konfigurasi',
        color: AppColors.brandSecondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminMasterDataScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.videocam_rounded,
        label: 'CCTV',
        subtitle: 'Kelola kamera',
        color: AppColors.roleSecurity,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CctvManagementScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.description_rounded,
        label: 'Dokumentasi',
        subtitle: 'User manual',
        color: AppColors.statusInfo,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminDocumentationScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Perintah',
        subtitle: 'Dari Owner',
        color: AppColors.roleOwner,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const EmployeeCommandScreen(roleColor: AppColors.roleAdmin))),
      ),
    ];
  }
}
