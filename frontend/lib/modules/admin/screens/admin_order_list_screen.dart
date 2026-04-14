import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'admin_order_detail_screen.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late final TabController _tabs;
  bool _isLoading = true;
  List<dynamic> _all = [];

  static const _roleColor = AppColors.roleAdmin;

  static const _statuses = [
    'all', 'pending', 'approved', 'in_progress', 'completed', 'cancelled'
  ];
  static const _labels = [
    'Semua', 'Pending', 'Disetujui', 'Berjalan', 'Selesai', 'Batal'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/admin/orders');
      if (res.data['success'] == true) {
        setState(() => _all = List<dynamic>.from(res.data['data'] ?? []));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filtered(String status) =>
      status == 'all' ? _all : _all.where((o) => o['status'] == status).toList();

  Color _statusColor(String s) => switch (s) {
        'admin_review' => AppColors.statusWarning,
        'approved' => AppColors.roleConsumer,
        'in_progress' => AppColors.statusSuccess,
        'completed' => AppColors.roleSO,
        'cancelled' => AppColors.statusDanger,
        _ => AppColors.textHint,
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => 'Menunggu',
        'so_review' => 'Review SO',
        'admin_review' => 'Perlu Aksi',
        'approved' => 'Disetujui',
        'in_progress' => 'Berjalan',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Semua Order',
        accentColor: _roleColor,
        showBack: true,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: _roleColor,
          labelColor: _roleColor,
          unselectedLabelColor: AppColors.textHint,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabs,
                children:
                    _statuses.map((s) => _buildList(_filtered(s))).toList(),
              ),
            ),
    );
  }

  Widget _buildList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('Tidak ada order.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildCard(orders[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final pic = order['pic'] as Map<String, dynamic>?;
    final needsAction = status == 'pending';
    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminOrderDetailScreen(orderId: order['id'] as String),
          ),
        ).then((_) => _load()),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order['order_number'] ?? '-',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                              color: sc,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order['deceased_name'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Text(
                    'PIC: ${pic?['name'] ?? '-'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (needsAction)
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.statusWarning, size: 20),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
