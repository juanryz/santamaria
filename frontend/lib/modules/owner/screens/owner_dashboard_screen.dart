import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_feedback_service.dart';
import '../../../core/services/notification_watcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/role_dashboard_header.dart';
import '../../../shared/widgets/senior_menu_grid.dart';
import '../../hrd/screens/kpi_management_screen.dart';
import 'owner_fleet_map_screen.dart';
import 'owner_command_screen.dart';
import 'death_cert_overview_screen.dart';
import 'cctv_monitoring_screen.dart';
import 'owner_order_list_screen.dart';
import 'owner_anomaly_list_screen.dart';
import 'owner_reports_screen.dart';

/// Owner Dashboard — simplified senior-friendly.
///
/// Pattern seragam untuk semua role:
/// - Header (RoleDashboardHeader)
/// - Stats cards (DashboardStatCard)
/// - Menu grid (SeniorMenuGrid) — fokus utama
/// - Detail sections (list pendek)
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final OwnerRepository _repo;
  final _api = ApiClient();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _notifWatcher = NotificationWatcher();

  Map<String, dynamic> _stats = {};
  List<dynamic> _orders = [];
  List<dynamic> _anomalies = [];
  bool _isLoading = true;

  static const _roleColor = AppColors.roleOwner;

  @override
  void initState() {
    super.initState();
    _repo = OwnerRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch satu per satu dengan try/catch terpisah — 1 endpoint gagal
      // tidak boleh bikin seluruh dashboard blank.
      try {
        final res = await _repo.getDashboard();
        if (res.data is Map && res.data['success'] == true) {
          final d = res.data['data'];
          if (d is Map) _stats = Map<String, dynamic>.from(d);
        }
      } catch (e) {
        debugPrint('Owner /dashboard error: $e');
      }

      try {
        final res = await _api.dio.get('/owner/orders');
        if (res.data is Map && res.data['success'] == true) {
          final d = res.data['data'];
          if (d is List) {
            _orders = List<dynamic>.from(d);
          } else if (d is Map && d['data'] is List) {
            _orders = List<dynamic>.from(d['data']);
          }
        }
      } catch (e) {
        debugPrint('Owner /orders error: $e');
      }

      try {
        final res = await _api.dio.get('/owner/purchase-orders/anomalies');
        if (res.data is Map && res.data['success'] == true) {
          final d = res.data['data'];
          if (d is List) _anomalies = List<dynamic>.from(d);
        }
      } catch (e) {
        debugPrint('Owner /anomalies error: $e');
      }

      // Feedback audio + haptic kalau jumlah notif bertambah sejak refresh terakhir
      _notifWatcher.check(
        newCount: _anomalies.length + _orders.length,
        severity: _anomalies.isNotEmpty
            ? NotificationSeverity.alarm
            : NotificationSeverity.normal,
      );
    } catch (e, st) {
      debugPrint('Owner dashboard fatal error: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DashboardNotification> _buildNotifications() {
    final list = <DashboardNotification>[];
    // Anomali dulu (paling urgent)
    for (final a in _anomalies.take(10)) {
      list.add(DashboardNotification(
        icon: Icons.warning_amber_rounded,
        title: (a['title'] as String?) ?? 'Anomali Terdeteksi',
        message: (a['description'] as String?) ?? 'Perlu perhatian',
        color: AppColors.statusDanger,
      ));
    }
    // Order terbaru
    for (final o in _orders.take(5)) {
      final deceased = o['deceased_name'] as String? ?? '-';
      list.add(DashboardNotification(
        icon: Icons.receipt_long_rounded,
        title: 'Order ${o['order_number'] ?? ''}',
        message: deceased,
        color: _roleColor,
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
    // Wrap seluruh build di try/catch manual via Builder,
    // supaya error apapun di widget nested tidak bikin layar blank.
    try {
      return _safeBuild(context);
    } catch (e, st) {
      debugPrint('Owner build error: $e\n$st');
      return _buildErrorFallback(e);
    }
  }

  Widget _buildErrorFallback(Object e) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.statusDanger),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: _roleColor,
                  minimumSize: const Size(160, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _safeBuild(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = _asString(user?['name']) ?? 'Owner';

    // Stats dari data — defensive parsing (jangan pakai `as int?`, bisa crash
    // kalau value datang sebagai String atau double dari backend).
    final ordersToday = _asInt(_stats['orders_today']) ??
        _asInt(_stats['today_order_count']) ??
        _orders.length;
    final revenueToday = _asDouble(_stats['revenue_today']) ??
        _asDouble(_stats['today_revenue']) ??
        _asDouble(_stats['total_revenue']) ??
        0;
    final activeDriversRaw = _stats['active_drivers'];
    final activeDrivers = activeDriversRaw is List
        ? activeDriversRaw.length
        : (_asInt(_stats['active_driver_count']) ??
            _asInt(_stats['drivers_on_duty']) ??
            0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative blobs
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
            bottom: 200, left: -40,
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
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HEADER (dengan bell notification)
                          RoleDashboardHeader(
                            roleLabel: 'Owner Portal',
                            roleColor: _roleColor,
                            greeting: _getGreeting(),
                            userName: userName,
                            notifications: _buildNotifications(),
                            badges: [
                              if (_anomalies.isNotEmpty)
                                HeaderBadge(
                                  label: '${_anomalies.length} Anomali',
                                  color: AppColors.statusDanger,
                                  icon: Icons.warning_amber_rounded,
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 2. STATS
                          _buildStatsRow(
                            ordersToday: ordersToday,
                            revenueToday: revenueToday,
                            activeDrivers: activeDrivers,
                          ),

                          const SizedBox(height: 24),

                          // 3. MENU GRID (fokus utama)
                          _buildMainMenuHeader(),
                          SeniorMenuGrid(
                            columns: 3,
                            items: _buildMenuItems(),
                          ),

                          const SizedBox(height: 8),

                          // 4. DETAIL SECTIONS
                          if (_anomalies.isNotEmpty) ...[
                            _buildSectionHeader('Anomali', Icons.warning_amber_rounded, AppColors.statusDanger),
                            _buildAnomaliesPreview(),
                            const SizedBox(height: 20),
                          ],
                          _buildSectionHeader('Order Terbaru', Icons.receipt_long_rounded, _roleColor),
                          _buildOrdersPreview(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required int ordersToday,
    required double revenueToday,
    required int activeDrivers,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DashboardStatCard(
              label: 'Order Hari Ini',
              value: ordersToday.toString(),
              icon: Icons.receipt_long_rounded,
              color: _roleColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardStatCard(
              label: 'Pendapatan',
              value: _compactCurrency(revenueToday),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.statusSuccess,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardStatCard(
              label: 'Driver Aktif',
              value: activeDrivers.toString(),
              icon: Icons.local_shipping_rounded,
              color: AppColors.brandSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Defensive parsing helpers — hindari `as int` crash kalau backend
  // kirim String/double/null.
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  String _compactCurrency(double v) {
    if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return _currency.format(v);
  }

  Widget _buildMainMenuHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(Icons.dashboard_rounded, color: _roleColor, size: 22),
          SizedBox(width: 8),
          Text(
            'Menu Utama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<SeniorMenuItem> _buildMenuItems() {
    return [
      SeniorMenuItem(
        icon: Icons.receipt_long_rounded,
        label: 'Order',
        subtitle: '${_orders.length} order',
        color: AppColors.roleSO,
        onTap: () => _navigateToOrders(),
      ),
      SeniorMenuItem(
        icon: Icons.warning_amber_rounded,
        label: 'Anomali',
        subtitle: _anomalies.isEmpty ? 'Aman' : '${_anomalies.length} perlu review',
        color: AppColors.statusDanger,
        onTap: () => _navigateToAnomalies(),
        badge: _anomalies.isEmpty ? null : _anomalies.length,
      ),
      SeniorMenuItem(
        icon: Icons.leaderboard_rounded,
        label: 'KPI',
        subtitle: 'Kinerja tim',
        color: AppColors.brandPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KpiManagementScreen()),
        ),
      ),
      SeniorMenuItem(
        icon: Icons.map_rounded,
        label: 'Armada',
        subtitle: 'Peta kendaraan',
        color: AppColors.roleDriver,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OwnerFleetMapScreen()),
        ),
      ),
      SeniorMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Perintah',
        subtitle: 'Kirim ke tim',
        color: AppColors.brandAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OwnerCommandScreen()),
        ),
      ),
      SeniorMenuItem(
        icon: Icons.description_rounded,
        label: 'Akta',
        subtitle: 'Monitor akta',
        color: AppColors.rolePemukaAgama,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DeathCertOverviewScreen()),
        ),
      ),
      SeniorMenuItem(
        icon: Icons.videocam_rounded,
        label: 'CCTV',
        subtitle: 'Monitoring',
        color: AppColors.roleSecurity,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CctvMonitoringScreen()),
        ),
      ),
      SeniorMenuItem(
        icon: Icons.analytics_rounded,
        label: 'Laporan',
        subtitle: 'Pendapatan',
        color: AppColors.statusSuccess,
        onTap: () => _navigateToReports(),
      ),
      SeniorMenuItem(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        subtitle: 'Semua order',
        color: AppColors.textSecondary,
        onTap: () => _navigateToOrders(),
      ),
    ];
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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

  Widget _buildAnomaliesPreview() {
    final preview = _anomalies.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: preview.map((a) {
          final title = (a['title'] as String?) ?? (a['description'] as String?) ?? 'Anomali';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusDanger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusDanger, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersPreview() {
    if (_orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Center(
            child: Text(
              'Belum ada order hari ini',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final preview = _orders.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: preview.map((o) {
          final orderNumber = (o['order_number'] as String?) ?? '-';
          final deceasedName = (o['deceased_name'] as String?) ?? '-';
          final status = (o['status'] as String?) ?? 'pending';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _roleColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _roleColor, size: 22),
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
                      Text(
                        '$orderNumber · $status',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OwnerOrderListScreen(title: 'Daftar Order'),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToAnomalies() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerAnomalyListScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerReportsScreen()),
    );
  }
}
