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
import 'gudang_orders_screen.dart';
import 'coffin_order_list_screen.dart';
import 'stock_alert_screen.dart';
import 'equipment_loan_list_screen.dart';
import 'stock_form_screen.dart';
import 'vehicle_maintenance_screen.dart';
import 'gudang_receive_screen.dart';
import 'gudang_item_return_screen.dart';
import 'stock_opname_screen.dart';
import 'stock_transfer_screen.dart';
import 'stock_damage_report_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

/// Gudang Dashboard — pattern seragam senior-friendly.
class GudangDashboardScreen extends StatefulWidget {
  const GudangDashboardScreen({super.key});

  @override
  State<GudangDashboardScreen> createState() => _GudangDashboardScreenState();
}

class _GudangDashboardScreenState extends State<GudangDashboardScreen> {
  final _api = ApiClient();
  final _notifWatcher = NotificationWatcher();
  int _lowStockCount = 0;
  int _pendingOrders = 0;
  int _totalOrders = 0;
  bool _isLoading = true;

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _api.dio.get('/gudang/stock-alerts').catchError((_) {
        return null as dynamic;
      });
      final orders = await _api.dio.get('/gudang/orders').catchError((_) {
        return null as dynamic;
      });

      if (alerts != null && alerts.data is Map && alerts.data['success'] == true) {
        _lowStockCount = (alerts.data['data'] as List?)?.length ?? 0;
      }
      if (orders != null && orders.data is Map && orders.data['success'] == true) {
        final list = orders.data['data'];
        final items = list is List
            ? list
            : (list is Map ? (list['data'] as List? ?? const []) : const []);
        _pendingOrders = items.where((o) =>
            ['confirmed', 'preparing', 'ready_to_dispatch']
                .contains(o['status'])).length;
        _totalOrders = items.length;
      }
      _notifWatcher.check(
        newCount: _pendingOrders + _lowStockCount,
        severity: _lowStockCount > 0
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
    if (_lowStockCount > 0) {
      list.add(DashboardNotification(
        icon: Icons.warning_amber_rounded,
        title: 'Stok Tipis',
        message: '$_lowStockCount item perlu di-restock',
        color: AppColors.statusDanger,
      ));
    }
    if (_pendingOrders > 0) {
      list.add(DashboardNotification(
        icon: Icons.inventory_rounded,
        title: 'Order Perlu Disiapkan',
        message: '$_pendingOrders order menunggu',
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
    final userName = (user?['name'] as String?) ?? 'Gudang';

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
                            roleLabel: 'Gudang',
                            roleColor: _roleColor,
                            greeting: _getGreeting(),
                            userName: userName,
                            notifications: _buildNotifications(),
                            badges: [
                              if (_lowStockCount > 0)
                                HeaderBadge(
                                  label: '$_lowStockCount Stok Tipis',
                                  color: AppColors.statusDanger,
                                  icon: Icons.warning_amber_rounded,
                                ),
                              if (_pendingOrders > 0)
                                HeaderBadge(
                                  label: '$_pendingOrders Perlu Siapkan',
                                  color: AppColors.statusWarning,
                                  icon: Icons.inventory_rounded,
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
                                    label: 'Order Aktif',
                                    value: _pendingOrders.toString(),
                                    icon: Icons.inventory_2_rounded,
                                    color: _roleColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Stok Tipis',
                                    value: _lowStockCount.toString(),
                                    icon: Icons.warning_amber_rounded,
                                    color: AppColors.statusDanger,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Total Order',
                                    value: _totalOrders.toString(),
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
            MaterialPageRoute(builder: (_) => const GudangOrdersScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.warning_amber_rounded,
        label: 'Alert Stok',
        subtitle: _lowStockCount > 0 ? '$_lowStockCount tipis' : 'Semua aman',
        color: AppColors.statusDanger,
        badge: _lowStockCount > 0 ? _lowStockCount : null,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockAlertScreen()))
            .then((_) => _loadData()),
      ),
      SeniorMenuItem(
        icon: Icons.inventory_rounded,
        label: 'Stok',
        subtitle: 'Kelola barang',
        color: AppColors.brandPrimary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockFormScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.inventory_2_rounded,
        label: 'Peti',
        subtitle: 'Workshop peti',
        color: AppColors.rolePemukaAgama,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CoffinOrderListScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.handshake_rounded,
        label: 'Pinjam Alat',
        subtitle: 'Equipment loan',
        color: AppColors.brandSecondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EquipmentLoanListScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.move_up_rounded,
        label: 'Transfer',
        subtitle: 'Antar lokasi',
        color: AppColors.statusInfo,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockTransferScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.fact_check_rounded,
        label: 'Opname',
        subtitle: 'Stock opname',
        color: AppColors.brandAccent,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockOpnameScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.inbox_rounded,
        label: 'Barang Masuk',
        subtitle: 'Terima barang',
        color: AppColors.statusSuccess,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GudangReceiveScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.assignment_return_rounded,
        label: 'Barang Kembali',
        subtitle: 'Retur barang',
        color: AppColors.roleGudang,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GudangItemReturnScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.broken_image_rounded,
        label: 'Rusak/Hilang',
        subtitle: 'Lapor barang',
        color: AppColors.statusDanger,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockDamageReportScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.build_rounded,
        label: 'Kendaraan',
        subtitle: 'Maintenance',
        color: AppColors.textSecondary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VehicleMaintenanceScreen())),
      ),
      SeniorMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Perintah',
        subtitle: 'Dari Owner',
        color: AppColors.roleOwner,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const EmployeeCommandScreen(roleColor: AppColors.roleGudang))),
      ),
      SeniorMenuItem(
        icon: Icons.beach_access_rounded,
        label: 'Cuti',
        subtitle: 'Ajukan cuti',
        color: AppColors.brandPrimary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyLeavesScreen())),
      ),
    ];
  }
}
