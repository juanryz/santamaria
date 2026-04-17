import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../vendor/screens/vendor_attendance_screen.dart';
import '../../kpi/screens/kpi_dashboard_screen.dart';
import '../../wage/screens/my_wage_claims_screen.dart';

class MusisiHomeScreen extends StatefulWidget {
  const MusisiHomeScreen({super.key});

  @override
  State<MusisiHomeScreen> createState() => _MusisiHomeScreenState();
}

class _MusisiHomeScreenState extends State<MusisiHomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  static const _roleColor = Color(0xFFE91E63); // pink musisi

  List<dynamic> _available = [];
  List<dynamic> _myOrders = [];
  int _totalEarnings = 0;

  late final TabController _tabController;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/vendor/assignments');
      if (res.data['success'] == true) {
        final all = List<dynamic>.from(res.data['data'] ?? []);
        _myOrders = all
            .where((a) =>
                a['status'] == 'confirmed' ||
                a['status'] == 'completed' ||
                a['status'] == 'present')
            .toList();
        _available = all
            .where((a) => a['status'] == 'pending' || a['status'] == 'assigned')
            .toList();
        _totalEarnings = all
            .where((a) => a['status'] == 'completed')
            .fold<int>(0, (sum, a) => sum + ((a['fee'] as num?)?.toInt() ?? 0));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acceptOrder(dynamic assignment) async {
    try {
      await _api.dio.put('/vendor/assignments/${assignment['id']}/accept');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil diambil')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Musisi / MC',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.brandPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KpiDashboardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const UnifiedLoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _roleColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: _roleColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tersedia'),
                  if (_available.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_available.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Order Saya'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Stats row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _statCard(
                          'Tersedia',
                          _available.length,
                          Icons.music_note,
                          _roleColor,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Diterima',
                          _myOrders
                              .where((a) => a['status'] != 'completed')
                              .length,
                          Icons.check_circle_outline,
                          Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Penghasilan',
                          _totalEarnings,
                          Icons.account_balance_wallet,
                          AppColors.statusSuccess,
                          isCurrency: true,
                        ),
                      ],
                    ),
                  ),
                  // Wage claims link
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassWidget(
                      borderRadius: 14,
                      child: ListTile(
                        leading:
                            Icon(Icons.account_balance_wallet, color: _roleColor),
                        title: const Text('Klaim Upah Layanan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle:
                            const Text('Ajukan & lihat status upah per order'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyWageClaimsScreen()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tabs content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAvailableTab(),
                        _buildMyOrdersTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────

  Widget _statCard(
    String label,
    int value,
    IconData icon,
    Color color, {
    bool isCurrency = false,
  }) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                isCurrency ? _currency.format(value) : '$value',
                style: TextStyle(
                  fontSize: isCurrency ? 14 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Available Tab ────────────────────────────────────────────────

  Widget _buildAvailableTab() {
    if (_available.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Tidak ada order yang tersedia saat ini'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _available.length,
      itemBuilder: (_, i) => _buildAvailableCard(_available[i]),
    );
  }

  Widget _buildAvailableCard(dynamic a) {
    final order = a['order'] ?? {};
    final fee = (a['fee'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.music_note, color: _roleColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (order['deceased_name'] != null)
                          Text(
                            'Alm. ${order['deceased_name']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  GlassStatusBadge(
                    label: 'BARU',
                    color: _roleColor,
                    icon: Icons.notifications_active,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(Icons.location_on,
                  order['funeral_home_name'] ?? order['destination_address'] ?? '-'),
              _infoRow(Icons.calendar_today, order['scheduled_at'] ?? '-'),
              if (fee > 0)
                _infoRow(Icons.payments, _currency.format(fee)),
              if (order['activity_description'] != null)
                _infoRow(Icons.info_outline, order['activity_description']),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _acceptOrder(a),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Ambil Order'),
                  style: FilledButton.styleFrom(backgroundColor: _roleColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── My Orders Tab ────────────────────────────────────────────────

  Widget _buildMyOrdersTab() {
    if (_myOrders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Belum ada order yang diambil'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myOrders.length,
      itemBuilder: (_, i) => _buildMyOrderCard(_myOrders[i]),
    );
  }

  Widget _buildMyOrderCard(dynamic a) {
    final order = a['order'] ?? {};
    final status = a['status'] ?? 'confirmed';
    final fee = (a['fee'] as num?)?.toInt() ?? 0;

    final statusColor = switch (status) {
      'completed' => AppColors.statusSuccess,
      'present' => Colors.blue,
      _ => Colors.orange,
    };
    final statusLabel = switch (status) {
      'completed' => 'Selesai',
      'present' => 'Hadir',
      'confirmed' => 'Dikonfirmasi',
      _ => status,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['order_number'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  GlassStatusBadge(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              if (order['deceased_name'] != null)
                Text('Alm. ${order['deceased_name']}',
                    style: const TextStyle(fontSize: 13)),
              _infoRow(Icons.location_on,
                  order['funeral_home_name'] ?? order['destination_address'] ?? '-'),
              _infoRow(Icons.calendar_today, order['scheduled_at'] ?? '-'),
              if (fee > 0)
                _infoRow(Icons.payments, _currency.format(fee)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorAttendanceScreen(
                              orderId: order['id'] ?? ''),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint, size: 16),
                      label: const Text('Presensi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
