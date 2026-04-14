import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../hrd/screens/kpi_management_screen.dart';
import 'owner_fleet_map_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final OwnerRepository _repo;
  final _api = ApiClient();

  Map<String, dynamic> _stats = {};
  List<dynamic> _orders = [];
  List<dynamic> _reports = [];
  List<dynamic> _anomalies = [];
  bool _isLoading = true;
  int _tab = 0; // 0=Dashboard, 1=Orders, 2=Anomali, 3=Laporan, 4=KPI

  // Map
  final MapController _mapCtrl = MapController();
  List<Marker> _driverMarkers = [];

  static const _roleColor = AppColors.roleOwner;

  @override
  void initState() {
    super.initState();
    _repo = OwnerRepository(ApiClient());
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getDashboard(),
        _api.dio.get('/owner/orders'),
        _api.dio.get('/owner/reports/daily'),
        _api.dio.get('/owner/purchase-orders/anomalies'),
      ]);

      if (results[0].data['success'] == true) {
        setState(() => _stats = results[0].data['data']);
      }
      if (results[1].data['success'] == true) {
        // Handle both direct list and paginated response
        final data = results[1].data['data'];
        if (data is Map && data['data'] != null) {
          setState(() => _orders = List<dynamic>.from(data['data']));
        } else {
          setState(() => _orders = List<dynamic>.from(data ?? []));
        }
      }
      if (results[2].data['success'] == true) {
        setState(() => _reports = List<dynamic>.from(results[2].data['data'] ?? []));
      }
      if (results[3].data['success'] == true) {
        setState(() => _anomalies = List<dynamic>.from(results[3].data['data'] ?? []));
      }
      _buildDriverMarkers();
    } catch (e) {
      debugPrint('Owner dashboard error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildDriverMarkers() {
    final drivers = (_stats['active_drivers'] as List?) ?? [];
    final markers = <Marker>[];
    for (final d in drivers) {
      if (d is! Map) continue;
      final lat = double.tryParse(d['location_lat']?.toString() ?? '');
      final lng = double.tryParse(d['location_lng']?.toString() ?? '');
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 30,
            height: 30,
            child: const Icon(
              Icons.location_on,
              color: AppColors.roleDriver,
              size: 30,
            ),
          ),
        );
      }
    }
    setState(() => _driverMarkers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Blob decorations
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
            child: Column(
              children: [
                _buildHeader(user),
                _buildTabBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildTabContent(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner Portal',
                    style: TextStyle(
                        color: _roleColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 11)),
                const SizedBox(height: 2),
                Text(user?['name'] ?? 'Owner',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const Spacer(),
            if (_anomalies.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.statusDanger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.statusDanger, size: 14),
                    const SizedBox(width: 4),
                    Text('${_anomalies.length} Anomali',
                        style: const TextStyle(
                            color: AppColors.statusDanger,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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
          ],
        ),
      );

  Widget _buildTabBar() {
    final tabs = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.receipt_long_outlined, 'Order'),
      (Icons.warning_amber_outlined, 'Anomali'),
      (Icons.analytics_outlined, 'Laporan'),
      (Icons.leaderboard_outlined, 'KPI'),
      (Icons.map_outlined, 'Armada'),
    ];
    return Container(
      color: AppColors.background,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _roleColor : AppColors.glassBorder,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: active ? _roleColor : AppColors.textHint,
                        size: 18),
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(
                            color: active ? _roleColor : AppColors.textHint,
                            fontSize: 9,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_tab) {
      0 => _buildDashboardTab(key: const ValueKey(0)),
      1 => _buildOrdersTab(key: const ValueKey(1)),
      2 => _buildAnomaliesTab(key: const ValueKey(2)),
      3 => _buildReportsTab(key: const ValueKey(3)),
      4 => const KpiManagementScreen(),
      _ => const OwnerFleetMapScreen(),
    };
  }

  // ── Tab 0: Dashboard ──────────────────────────────────────────────────────

  Widget _buildDashboardTab({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueCard(),
            const SizedBox(height: 16),
            _buildOrderRingChart(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildQuickInfo(),
            const SizedBox(height: 20),
            _buildFleetMap(),
            const SizedBox(height: 20),
            if (_reports.isNotEmpty) _buildLatestReport(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildRevenueCard() => GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: _roleColor.withValues(alpha: 0.07),
        borderColor: _roleColor.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTAL REVENUE',
                style: TextStyle(
                    color: _roleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
              'Rp ${NumberFormat('#,###').format(double.tryParse(_stats['total_revenue']?.toString() ?? '0') ?? 0)}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              '${int.tryParse(_stats['total_orders']?.toString() ?? '0') ?? 0} total order',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildOrderRingChart() {
    final active = (int.tryParse(_stats['active_orders']?.toString() ?? '0') ?? 0).toDouble();
    final completed = (int.tryParse(_stats['completed_orders']?.toString() ?? '0') ?? 0).toDouble();
    final pending = (int.tryParse(_stats['pending_orders']?.toString() ?? '0') ?? 0).toDouble();
    final total = active + completed + pending;

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISTRIBUSI ORDER',
              style: TextStyle(color: _roleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _RingChartPainter(
                    segments: [
                      (active, AppColors.roleConsumer),
                      (completed, AppColors.statusSuccess),
                      (pending, AppColors.statusWarning),
                    ],
                    strokeWidth: 14,
                  ),
                  child: Center(
                    child: Text('${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Aktif', active.toInt(), AppColors.roleConsumer),
                    const SizedBox(height: 8),
                    _legendItem('Selesai', completed.toInt(), AppColors.statusSuccess),
                    const SizedBox(height: 8),
                    _legendItem('Pending', pending.toInt(), AppColors.statusWarning),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const Spacer(),
      Text('$count', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
    ],
  );

  Widget _buildStatsGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _stat('Order Aktif',
              (_stats['active_orders'] ?? 0).toString(),
              Icons.local_shipping,
              AppColors.roleConsumer),
          _stat('Order Hari Ini',
              (_stats['orders_today'] ?? 0).toString(),
              Icons.today,
              AppColors.statusSuccess),
          _stat('Driver On Duty',
              (_stats['drivers_on_duty'] ?? 0).toString(),
              Icons.drive_eta_outlined,
              AppColors.roleSO),
          _stat('Pending PO',
              (int.tryParse(_stats['pending_po']?.toString() ?? '0') ?? 0).toString(),
              Icons.receipt_outlined,
              AppColors.statusWarning),
        ],
      );

  Widget _stat(String label, String val, IconData icon, Color color) =>
      GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: color.withValues(alpha: 0.07),
        borderColor: color.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const Spacer(),
            Text(val,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      );

  Widget _buildQuickInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Armada',
              style: TextStyle(
                  color: _roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          GlassWidget(
            borderRadius: 16,
            blurSigma: 10,
            tint: _roleColor.withValues(alpha: 0.06),
            borderColor: _roleColor.withValues(alpha: 0.18),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_outlined,
                      color: _roleColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${_stats['drivers_on_duty'] ?? 0} driver on duty',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                          '${_driverMarkers.length} kendaraan terlacak di peta',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildFleetMap() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Armada Real-time',
              style: TextStyle(
                  color: _roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: LatLng(-6.2088, 106.8456),
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.santamaria.funeral',
                  ),
                  MarkerLayer(markers: _driverMarkers),
                ],
              ),
            ),
          ),
          if (_driverMarkers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tidak ada driver On Duty saat ini.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ),
        ],
      );

  Widget _buildLatestReport() {
    if (_reports.isEmpty) return const SizedBox.shrink();
    final report = _reports.first as Map<String, dynamic>;
    return GlassWidget(
      borderRadius: 18,
      blurSigma: 16,
      tint: AppColors.statusWarning.withValues(alpha: 0.06),
      borderColor: AppColors.statusWarning.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.statusWarning, size: 16),
              const SizedBox(width: 8),
              const Text('Laporan Harian AI',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              Text(
                _formatDate(report['report_date']),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report['ai_narrative'] as String? ?? '-',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Orders ─────────────────────────────────────────────────────────

  Widget _buildOrdersTab({Key? key}) {
    if (_orders.isEmpty) {
      return Center(
        key: key,
        child: const Text('Tidak ada order.',
            style: TextStyle(color: AppColors.textHint)),
      );
    }
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final status = o['status'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o['order_number'] ?? '-',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(o['deceased_name'] ?? '-',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('PIC: ${(o['pic'] as Map?)?['name'] ?? '-'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            _statusChip(status),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String s) {
    final (color, label) = switch (s) {
      'admin_review' => (AppColors.statusWarning, 'Perlu Aksi'),
      'approved' => (AppColors.roleConsumer, 'Disetujui'),
      'in_progress' => (AppColors.statusSuccess, 'Berjalan'),
      'completed' => (AppColors.roleSO, 'Selesai'),
      'cancelled' => (AppColors.statusDanger, 'Batal'),
      _ => (AppColors.textHint, s),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  // ── Tab 2: Anomalies ──────────────────────────────────────────────────────

  Widget _buildAnomaliesTab({Key? key}) {
    if (_anomalies.isEmpty) {
      return Center(
        key: key,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline,
                color: AppColors.statusSuccess, size: 48),
            SizedBox(height: 12),
            Text('Tidak ada anomali harga.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _anomalies.length,
      itemBuilder: (_, i) => _buildAnomalyCard(_anomalies[i]),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> po) {
    final variance = po['price_variance_pct'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 18,
        blurSigma: 16,
        tint: AppColors.statusDanger.withValues(alpha: 0.05),
        borderColor: AppColors.statusDanger.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.statusDanger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(po['item_name'] ?? '-',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('Harga Diajukan',
                'Rp ${NumberFormat('#,###').format(double.tryParse(po['proposed_price']?.toString() ?? '0') ?? 0)}'),
            _infoRow('Harga Pasar',
                'Rp ${NumberFormat('#,###').format(double.tryParse(po['market_price']?.toString() ?? '0') ?? 0)}'),
            if (variance != null)
              _infoRow('Selisih',
                  '+${(variance as num).toStringAsFixed(1)}% di atas pasar'),
            if (po['ai_analysis'] != null) ...[
              const SizedBox(height: 8),
              Text(po['ai_analysis'] as String,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: AppColors.statusWarning, size: 14),
                  SizedBox(width: 6),
                  Text('Menunggu tindakan Purchasing',
                      style: TextStyle(
                          color: AppColors.statusWarning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
            Expanded(
              child: Text(val,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12)),
            ),
          ],
        ),
      );

  // ── Tab 3: Reports ────────────────────────────────────────────────────────

  Widget _buildReportsTab({Key? key}) {
    if (_reports.isEmpty) {
      return Center(
        key: key,
        child: const Text('Belum ada laporan.',
            style: TextStyle(color: AppColors.textHint)),
      );
    }
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _reports.length,
      itemBuilder: (_, i) => _buildReportCard(_reports[i]),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: GlassWidget(
          borderRadius: 18,
          blurSigma: 16,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.statusWarning, size: 16),
                  const SizedBox(width: 8),
                  Text(_formatDate(r['report_date']),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                r['ai_narrative'] as String? ?? '-',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (r['total_orders'] != null || r['total_revenue'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(
                        'Order',
                        (r['total_orders'] ?? 0).toString(),
                        AppColors.roleConsumer),
                    const SizedBox(width: 12),
                    _miniStat(
                        'Revenue',
                        'Rp ${NumberFormat.compact().format(double.tryParse(r['total_revenue']?.toString() ?? '0') ?? 0)}',
                        AppColors.statusSuccess),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _miniStat(String label, String val, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 10)),
          ],
        ),
      );

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('d MMMM yyyy', 'id')
          .format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }
}

class _RingChartPainter extends CustomPainter {
  final List<(double value, Color color)> segments;
  final double strokeWidth;

  _RingChartPainter({required this.segments, this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final total = segments.fold<double>(0, (sum, s) => sum + s.$1);
    if (total == 0) {
      // Draw empty ring
      canvas.drawCircle(center, radius, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.grey.withValues(alpha: 0.15));
      return;
    }

    double startAngle = -pi / 2;
    for (final (value, color) in segments) {
      if (value <= 0) continue;
      final sweep = (value / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter old) => true;
}
