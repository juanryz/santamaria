import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Owner — laporan pendapatan & statistik (read-only).
class OwnerReportsScreen extends StatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen> {
  final _api = ApiClient();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  static const _roleColor = AppColors.roleOwner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/owner/dashboard');
      if (res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        if (d is Map) _stats = Map<String, dynamic>.from(d);
      }
    } catch (e) {
      debugPrint('Owner reports error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _asDouble(_stats['total_revenue']) ?? 0;
    final todayRevenue = _asDouble(_stats['revenue_today']) ??
        _asDouble(_stats['today_revenue']) ??
        0;
    final totalOrders = _asInt(_stats['total_orders']) ?? 0;
    final ordersToday = _asInt(_stats['orders_today']) ?? 0;
    final activeOrders = _asInt(_stats['active_orders']) ?? 0;
    final driversOnDuty = _asInt(_stats['drivers_on_duty']) ?? 0;
    final pendingPo = _asInt(_stats['pending_po']) ?? 0;
    final poAnomalies = _asInt(_stats['po_anomalies']) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Laporan',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                children: [
                  _buildSection('Pendapatan', [
                    _buildMetric(
                      'Pendapatan Hari Ini',
                      _currency.format(todayRevenue),
                      Icons.today_rounded,
                      AppColors.statusSuccess,
                    ),
                    _buildMetric(
                      'Total Pendapatan',
                      _currency.format(totalRevenue),
                      Icons.account_balance_wallet_rounded,
                      AppColors.brandPrimary,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Order', [
                    _buildMetric(
                      'Order Hari Ini',
                      ordersToday.toString(),
                      Icons.receipt_long_rounded,
                      _roleColor,
                    ),
                    _buildMetric(
                      'Order Aktif',
                      activeOrders.toString(),
                      Icons.trending_up_rounded,
                      AppColors.statusInfo,
                    ),
                    _buildMetric(
                      'Total Order',
                      totalOrders.toString(),
                      Icons.list_alt_rounded,
                      AppColors.brandSecondary,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Operasional', [
                    _buildMetric(
                      'Driver Aktif',
                      driversOnDuty.toString(),
                      Icons.local_shipping_rounded,
                      AppColors.roleDriver,
                    ),
                    _buildMetric(
                      'PO Pending',
                      pendingPo.toString(),
                      Icons.pending_actions_rounded,
                      AppColors.statusWarning,
                    ),
                    _buildMetric(
                      'Anomali PO',
                      poAnomalies.toString(),
                      Icons.warning_amber_rounded,
                      AppColors.statusDanger,
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...items.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: w,
            )),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}
