import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'payment_verify_screen.dart';
import 'purchasing_wage_approval_screen.dart';
import 'photographer_wage_approval_screen.dart';
import 'membership_payment_screen.dart';
import 'petty_cash_screen.dart';
import '../../wage/screens/wage_management_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class PurchasingDashboardScreen extends StatefulWidget {
  const PurchasingDashboardScreen({super.key});

  @override
  State<PurchasingDashboardScreen> createState() => _PurchasingDashboardScreenState();
}

class _PurchasingDashboardScreenState extends State<PurchasingDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  static const _roleColor = AppColors.rolePurchasing;

  List<dynamic> _pendingPayments = [];
  List<dynamic> _pendingProcurements = [];
  List<dynamic> _pendingFieldTeam = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      try {
        final r1 = await _api.dio.get('/finance/consumer-payments/pending');
        if (r1.data['success'] == true) _pendingPayments = List<dynamic>.from(r1.data['data'] ?? []);
      } catch (_) {}
      try {
        final r2 = await _api.dio.get('/finance/procurement-requests/pending');
        if (r2.data['success'] == true) _pendingProcurements = List<dynamic>.from(r2.data['data'] ?? []);
      } catch (_) {}
      try {
        final r3 = await _api.dio.get('/finance/field-team/pending');
        if (r3.data['success'] == true) _pendingFieldTeam = List<dynamic>.from(r3.data['data'] ?? []);
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Purchasing',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 24),
                  _buildMenuGrid(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard('Payment\nMenunggu', _pendingPayments.length, Icons.payment, Colors.orange),
        const SizedBox(width: 12),
        _statCard('Pengadaan\nMenunggu', _pendingProcurements.length, Icons.shopping_cart, Colors.blue),
        const SizedBox(width: 12),
        _statCard('Tim Lapangan\nMenunggu', _pendingFieldTeam.length, Icons.people, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menus = [
      {'icon': Icons.payment, 'label': 'Verifikasi Payment', 'color': Colors.orange, 'screen': const PaymentVerifyScreen()},
      {'icon': Icons.shopping_cart, 'label': 'Approval Pengadaan', 'color': Colors.blue, 'screen': null},
      {'icon': Icons.people, 'label': 'Upah Tim Lapangan', 'color': Colors.green, 'screen': const PurchasingWageApprovalScreen()},
      {'icon': Icons.account_balance_wallet, 'label': 'Kelola Upah Layanan', 'color': const Color(0xFF3A5E8C), 'screen': const WageManagementScreen()},
      // v1.40 — Upah harian tukang foto
      {'icon': Icons.camera_alt, 'label': 'Upah Harian Foto', 'color': const Color(0xFF8E44AD), 'screen': const PhotographerWageApprovalScreen()},
      // v1.39 — Iuran Membership
      {'icon': Icons.card_membership, 'label': 'Iuran Membership', 'color': Colors.teal, 'screen': const MembershipPaymentScreen()},
      // v1.39 — Kas Kecil
      {'icon': Icons.account_balance_wallet, 'label': 'Kas Kecil Kantor', 'color': Colors.amber[700], 'screen': const PettyCashScreen()},
      // v1.39 — Self-service cuti
      {'icon': Icons.event_available, 'label': 'Cuti & Izin Saya', 'color': Colors.indigo, 'screen': const MyLeavesScreen()},
      {'icon': Icons.store, 'label': 'Bayar Supplier', 'color': Colors.purple, 'screen': null},
      {'icon': Icons.receipt_long, 'label': 'Laporan Tagihan', 'color': Colors.teal, 'screen': null},
      {'icon': Icons.bar_chart, 'label': 'Laporan Bulanan', 'color': Colors.indigo, 'screen': null},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) {
        final m = menus[i];
        return GlassWidget(
          borderRadius: 16,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final screen = m['screen'] as Widget?;
              if (screen != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m['icon'] as IconData, color: m['color'] as Color, size: 32),
                const SizedBox(height: 8),
                Text(
                  m['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
