import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'admin_order_list_screen.dart';
import 'admin_order_detail_screen.dart';
import 'admin_package_management_screen.dart';
import 'admin_fleet_management_screen.dart';
import '../../../shared/widgets/change_password_dialog.dart';
import 'admin_documentation_screen.dart';
import 'admin_master_data_screen.dart';
import '../../../shared/screens/employee_command_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminRepository _repo;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentOrders = [];
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
        setState(() {
          _stats = res.data['data']['stats'];
          _recentOrders = res.data['data']['recent_orders'];
        });
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Color blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    _buildStatsGrid(),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildAiInsightCard(),
                    const SizedBox(height: 28),
                    const Text('Order Terbaru',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRecentOrders(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = context.read<AuthProvider>().user?['name'] ?? 'Admin';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Portal',
                  style: TextStyle(
                      color: _roleColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text('Halo, $name',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const Spacer(),
        GlassWidget(
          borderRadius: 12,
          blurSigma: 10,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(8),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmployeeCommandScreen(roleColor: AppColors.roleAdmin))),
          child: const Icon(Icons.campaign, color: AppColors.roleAdmin, size: 20),
        ),
        const SizedBox(width: 8),
        GlassWidget(
          borderRadius: 12,
          blurSigma: 10,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(8),
          onTap: () async {
            final nav = Navigator.of(context);
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            nav.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
              (_) => false,
            );
          },
          child: const Icon(Icons.logout,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(width: 8),
        GlassWidget(
          borderRadius: 12,
          blurSigma: 10,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(8),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => ChangePasswordDialog(
                apiClient: ApiClient(),
                isPin: false,
              ),
            );
          },
          child: const Icon(Icons.settings_outlined,
              color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (
        Icons.dataset_outlined,
        'Master Data',
        'Paket, threshold, armada, & lainnya',
        () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AdminMasterDataScreen())),
      ),
      (
        Icons.inventory_2_outlined,
        'Manajemen Paket',
        'Kelola paket & item stok',
        () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AdminPackageManagementScreen())),
      ),
      (
        Icons.local_shipping_outlined,
        'Manajemen Armada',
        'Daftar mobil jenazah & status',
        () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AdminFleetManagementScreen())),
      ),
      (
        Icons.photo_camera_back_outlined,
        'Dokumentasi (CRM)',
        'Upload foto & video pasca acara',
        () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AdminDocumentationScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kelola Master Data',
            style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ...actions.map((a) {
          final (icon, title, subtitle, onTap) = a;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassWidget(
              borderRadius: 16,
              blurSigma: 10,
              tint: _roleColor.withValues(alpha: 0.05),
              borderColor: _roleColor.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(14),
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: _roleColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        Text(subtitle,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textHint, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openOrderList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminOrderListScreen()),
    ).then((_) => _loadData());
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard('Total Order', (_stats['total_orders'] ?? 0).toString(),
            Icons.receipt_long, AppColors.roleConsumer, _openOrderList),
        _statCard('Selesai Hari Ini', (_stats['completed_today'] ?? 0).toString(),
            Icons.check_circle, AppColors.statusSuccess, _openOrderList),
        _statCard('Aktif', (_stats['active_orders'] ?? 0).toString(),
            Icons.local_shipping, AppColors.statusSuccess, _openOrderList),
        _statCard(
          'Revenue',
          'Rp ${( (double.tryParse(_stats['total_revenue']?.toString() ?? '0') ?? 0) / 1000000).toStringAsFixed(1)}M',
          Icons.payments,
          AppColors.brandPrimary,
          null,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      VoidCallback? onTap) {
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    final active = int.tryParse(_stats['active_orders']?.toString() ?? '0') ?? 0;
    final completedToday = int.tryParse(_stats['completed_today']?.toString() ?? '0') ?? 0;
    final insight = 'Sistem berjalan normal secara otomatis. $active order sedang berjalan, $completedToday selesai hari ini.';

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.statusSuccess.withValues(alpha: 0.06),
      borderColor: AppColors.statusSuccess.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.statusSuccess, size: 20),
              const SizedBox(width: 12),
              const Text('Semua Berjalan Baik',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('NORMAL',
                    style: TextStyle(
                        color: AppColors.statusSuccess,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return const Center(
          child: Text('Tidak ada order terbaru',
              style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentOrders.length,
      itemBuilder: (context, index) {
        final order = _recentOrders[index];
        final consumer = order['pic'] as Map<String, dynamic>?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassWidget(
            borderRadius: 20,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminOrderDetailScreen(orderId: order['id'] as String),
              ),
            ).then((_) => _loadData()),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _roleColor.withValues(alpha: 0.10),
                  ),
                  child: Icon(Icons.person,
                      color: _roleColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(consumer?['name'] ?? 'Konsumen',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold)),
                      Text(
                          'Order ${order['order_number']} • ${order['status']}',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
