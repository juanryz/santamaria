import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_feedback_service.dart';
import '../../../core/services/notification_watcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/role_dashboard_header.dart';
import '../../../shared/widgets/senior_menu_grid.dart';
import 'so_order_detail_screen.dart';
import 'so_create_order_screen.dart';
import 'so_crm_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';
import '../../../shared/screens/role_inventory_screen.dart';
import 'membership_list_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

/// Service Officer Dashboard — pattern seragam senior-friendly.
class SODashboardScreen extends StatefulWidget {
  const SODashboardScreen({super.key});

  @override
  State<SODashboardScreen> createState() => _SODashboardScreenState();
}

class _SODashboardScreenState extends State<SODashboardScreen> {
  late final SORepository _repo;
  final _notifWatcher = NotificationWatcher();
  List<dynamic> _orders = [];
  bool _isLoading = true;

  static const _roleColor = AppColors.roleSO;

  @override
  void initState() {
    super.initState();
    _repo = SORepository(ApiClient());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getOrders();
      if (res.data['success'] == true) {
        _orders = res.data['data'] as List;
      }
      _notifWatcher.check(
        newCount: _pendingCount,
        severity: NotificationSeverity.high,
      );
    } catch (_) {
      // silent error — handled in UI
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DashboardNotification> _buildNotifications() {
    return _orders
        .where((o) => o['status'] == 'pending')
        .take(10)
        .map((o) => DashboardNotification(
              icon: Icons.pending_actions_rounded,
              title: 'Perlu Aksi: ${o['order_number'] ?? ''}',
              message: (o['deceased_name'] as String?) ?? '-',
              color: AppColors.statusWarning,
            ))
        .toList();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  int get _pendingCount => _orders.where((o) => o['status'] == 'pending').length;

  int get _activeCount => _orders.where((o) =>
    ['confirmed', 'in_progress', 'preparing', 'ready_to_dispatch',
     'driver_assigned', 'delivering_equipment', 'equipment_arrived',
     'picking_up_body', 'body_arrived', 'in_ceremony',
     'heading_to_burial'].contains(o['status'])).length;

  int get _completedToday {
    final today = DateTime.now();
    return _orders.where((o) {
      if (o['status'] != 'completed') return false;
      final dateStr = o['completed_at'] as String?;
      if (dateStr == null) return false;
      final d = DateTime.tryParse(dateStr);
      return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = (user?['name'] as String?) ?? 'Service Officer';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SOCreateOrderScreen(repo: _repo)),
        ).then((_) => _loadOrders()),
        backgroundColor: _roleColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle, size: 24),
        label: const Text(
          'Order Baru',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
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
          Positioned(
            bottom: 160, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HEADER (dengan bell notification)
                          RoleDashboardHeader(
                            roleLabel: 'Service Officer',
                            roleColor: _roleColor,
                            greeting: _getGreeting(),
                            userName: userName,
                            notifications: _buildNotifications(),
                            badges: [
                              if (_pendingCount > 0)
                                HeaderBadge(
                                  label: '$_pendingCount Perlu Aksi',
                                  color: AppColors.statusWarning,
                                  icon: Icons.notifications_active_rounded,
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 2. STATS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Perlu Aksi',
                                    value: _pendingCount.toString(),
                                    icon: Icons.pending_actions_rounded,
                                    color: AppColors.statusWarning,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Sedang Proses',
                                    value: _activeCount.toString(),
                                    icon: Icons.autorenew_rounded,
                                    color: _roleColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DashboardStatCard(
                                    label: 'Selesai Hari Ini',
                                    value: _completedToday.toString(),
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.statusSuccess,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. MENU GRID
                          _buildSectionHeader('Menu Utama', Icons.dashboard_rounded),
                          SeniorMenuGrid(
                            columns: 3,
                            items: [
                              SeniorMenuItem(
                                icon: Icons.receipt_long_rounded,
                                label: 'Daftar Order',
                                subtitle: '${_orders.length} total',
                                color: _roleColor,
                                onTap: () {
                                  // scroll to orders section below
                                },
                              ),
                              SeniorMenuItem(
                                icon: Icons.people_alt_rounded,
                                label: 'CRM',
                                subtitle: 'Prospek & Visit',
                                color: AppColors.brandSecondary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SoCrmScreen()),
                                ),
                              ),
                              SeniorMenuItem(
                                icon: Icons.inventory_rounded,
                                label: 'Stok',
                                subtitle: 'Inventori SO',
                                color: AppColors.brandPrimary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RoleInventoryScreen()),
                                ),
                              ),
                              SeniorMenuItem(
                                icon: Icons.card_membership_rounded,
                                label: 'Anggota',
                                subtitle: 'Keanggotaan',
                                color: AppColors.brandAccent,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MembershipListScreen()),
                                ),
                              ),
                              SeniorMenuItem(
                                icon: Icons.campaign_rounded,
                                label: 'Perintah',
                                subtitle: 'Dari Owner',
                                color: AppColors.roleOwner,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EmployeeCommandScreen(
                                      roleColor: AppColors.roleSO,
                                    ),
                                  ),
                                ),
                              ),
                              SeniorMenuItem(
                                icon: Icons.beach_access_rounded,
                                label: 'Cuti',
                                subtitle: 'Ajukan cuti',
                                color: AppColors.statusInfo,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyLeavesScreen()),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 4. ORDERS LIST PREVIEW
                          _buildSectionHeader('Order Terbaru', Icons.receipt_long_rounded),
                          _buildOrdersList(),
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

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
                SizedBox(height: 8),
                Text(
                  'Belum ada order',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap tombol "Order Baru" untuk mulai',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _orders.take(8).map((o) => _buildOrderCard(o)).toList(),
      ),
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final orderNumber = (o['order_number'] as String?) ?? '-';
    final deceasedName = (o['deceased_name'] as String?) ?? '-';
    final status = (o['status'] as String?) ?? 'pending';
    final picName = (o['pic_name'] as String?) ?? '-';
    final (statusColor, statusLabel) = _statusMeta(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SOOrderDetailScreen(orderId: o['id'], repo: _repo),
            ),
          ).then((_) => _loadOrders()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _roleColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: _roleColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_rounded, color: _roleColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deceasedName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$orderNumber · $picName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, String) _statusMeta(String status) {
    switch (status) {
      case 'pending':
        return (AppColors.statusWarning, 'Pending');
      case 'confirmed':
        return (AppColors.statusInfo, 'Confirmed');
      case 'in_progress':
      case 'preparing':
      case 'ready_to_dispatch':
      case 'driver_assigned':
      case 'delivering_equipment':
      case 'equipment_arrived':
      case 'picking_up_body':
      case 'body_arrived':
      case 'in_ceremony':
      case 'heading_to_burial':
        return (_roleColor, 'Sedang Proses');
      case 'completed':
        return (AppColors.statusSuccess, 'Selesai');
      case 'cancelled':
        return (AppColors.statusDanger, 'Dibatalkan');
      default:
        return (AppColors.textHint, status);
    }
  }
}
