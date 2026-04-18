import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'finance_report_screen.dart';
import 'finance_transaction_screen.dart';
import 'finance_receivables_screen.dart';
import 'payment_reminder_screen.dart';
import '../../purchasing/screens/purchasing_wage_approval_screen.dart';
import '../../purchasing/screens/purchasing_supplier_detail_screen.dart';

const Map<String, String> categoryLabels = {
  'jasa_funeral': 'Jasa Funeral',
  'paket_dasar': 'Paket Dasar',
  'paket_premium': 'Paket Premium',
  'paket_eksklusif': 'Paket Eksklusif',
  'add_on': 'Add-On',
  'pengadaan': 'Pengadaan',
  'upah_tukang_jaga': 'Upah Tukang Jaga',
  'vendor_dekor': 'Vendor Dekorasi',
  'vendor_konsumsi': 'Vendor Konsumsi',
  'vendor_pemuka_agama': 'Vendor Pemuka Agama',
  'vendor_foto': 'Vendor Foto',
  'vendor_angkat_peti': 'Vendor Angkat Peti',
  'operasional': 'Operasional',
  'manual_correction': 'Koreksi Manual',
};

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _dashData = {};
  Map<String, dynamic> _thisMonth = {};
  List<dynamic> _monthlyTrend = [];
  List<dynamic> _receivables = [];
  List<dynamic> _unpaidWages = [];
  List<dynamic> _pendingPaymentVerify = [];
  List<dynamic> _pendingProcurementApproval = [];
  List<dynamic> _pendingSupplierPayment = [];

  static const _roleColor = AppColors.roleFinance;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _apiClient.dio.get('/finance/dashboard');
      if (!mounted) return;
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _dashData = data;
        _thisMonth = (data['this_month'] as Map<String, dynamic>?) ?? {};
        _monthlyTrend = (data['monthly_trend'] as List<dynamic>?) ?? [];
        _receivables = (data['receivables'] as List<dynamic>?) ?? [];
        _unpaidWages = (data['unpaid_wages'] as List<dynamic>?) ?? [];
        _pendingPaymentVerify = (data['pending_payment_verify'] as List<dynamic>?) ?? [];
        _pendingProcurementApproval = (data['pending_procurement_approval'] as List<dynamic>?) ?? [];
        _pendingSupplierPayment = (data['pending_supplier_payment'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data dashboard. Periksa koneksi Anda.';
          _isLoading = false;
        });
      }
    }
  }

  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?['name'] ?? 'Finance';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(userName),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      _buildError()
                    else ...[
                      _buildStatCards(),
                      const SizedBox(height: 28),
                      _buildPendingActionCards(),
                      const SizedBox(height: 28),
                      _buildMonthlyTrendTable(),
                      const SizedBox(height: 28),
                      _buildReceivablesSection(),
                      const SizedBox(height: 28),
                      _buildUnpaidWagesSection(),
                      const SizedBox(height: 28),
                      _buildQuickActions(),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finance Dashboard',
              style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Halo, $userName',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Spacer(),
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
          child: const Icon(
            Icons.logout,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.statusDanger.withValues(alpha: 0.05),
      borderColor: AppColors.statusDanger.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.statusDanger,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _roleColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final income = _toDouble(_thisMonth['income']);
    final expense = _toDouble(_thisMonth['expense']);
    final profit = _toDouble(_thisMonth['profit'] ?? (income - expense));
    final lastIncome = _toDouble(
      _thisMonth['last_month_income'] ?? _dashData['last_month']?['income'],
    );
    final incomeDiff = lastIncome > 0
        ? (income - lastIncome) / lastIncome
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bulan Ini',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Pendapatan',
                value: _currency.format(income),
                valueColor: AppColors.statusSuccess,
                icon: Icons.trending_up,
                iconColor: AppColors.statusSuccess,
                badge: lastIncome > 0 ? _buildArrow(incomeDiff) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'Pengeluaran',
                value: _currency.format(expense),
                valueColor: AppColors.statusDanger,
                icon: Icons.trending_down,
                iconColor: AppColors.statusDanger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'Laba Bersih',
                value: _currency.format(profit.abs()),
                valueColor: profit >= 0
                    ? AppColors.statusSuccess
                    : AppColors.statusDanger,
                icon: profit >= 0
                    ? Icons.account_balance_wallet
                    : Icons.money_off,
                iconColor: profit >= 0
                    ? AppColors.statusSuccess
                    : AppColors.statusDanger,
                prefix: profit < 0 ? '-' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrow(double diff) {
    final isUp = diff >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 10,
          color: isUp ? AppColors.statusSuccess : AppColors.statusDanger,
        ),
        Text(
          '${(diff.abs() * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 9,
            color: isUp ? AppColors.statusSuccess : AppColors.statusDanger,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    Widget? badge,
    String? prefix,
  }) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const Spacer(),
              ?badge,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${prefix ?? ''}$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Butuh Tindakan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _pendingCard(
                icon: Icons.verified_user_outlined,
                label: 'Verifikasi\nPembayaran',
                count: _pendingPaymentVerify.length,
                color: Colors.orange,
                onTap: () {
                  // Navigate to payment verify list (receivables screen covers this)
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FinanceReceivablesScreen()));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pendingCard(
                icon: Icons.shopping_cart_checkout,
                label: 'Pengadaan\nButuh Approval',
                count: _pendingProcurementApproval.length,
                color: Colors.blue,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _pendingCard(
                icon: Icons.store_outlined,
                label: 'Tagihan\nSupplier',
                count: _pendingSupplierPayment.length,
                color: Colors.purple,
                onTap: () {
                  if (_pendingSupplierPayment.isNotEmpty) {
                    final first = _pendingSupplierPayment.first;
                    final id = first['id']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PurchasingSupplierDetailScreen(transactionId: id),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pendingCard(
                icon: Icons.groups_outlined,
                label: 'Upah Pekerja\nLepas',
                count: _unpaidWages.length,
                color: AppColors.statusWarning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchasingWageApprovalScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pendingCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: count > 0
          ? color.withValues(alpha: 0.05)
          : AppColors.glassWhite,
      borderColor: count > 0
          ? color.withValues(alpha: 0.25)
          : AppColors.glassBorder,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? color.withValues(alpha: 0.15)
                  : AppColors.glassBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: count > 0 ? color : AppColors.textHint,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendTable() {
    if (_monthlyTrend.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '6 Bulan Terakhir',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassWidget(
          borderRadius: 16,
          blurSigma: 10,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header row
              Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bulan',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Pendapatan',
                      style: TextStyle(
                        color: AppColors.statusSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Pengeluaran',
                      style: TextStyle(
                        color: AppColors.statusDanger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Laba',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              ...(_monthlyTrend.take(6).map((m) {
                final income = _toDouble(m['income']);
                final expense = _toDouble(m['expense']);
                final profit = income - expense;
                final monthLabel = _monthAbbr(m['month']?.toString() ?? '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          monthLabel,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _compactCurrency(income),
                          style: const TextStyle(
                            color: AppColors.statusSuccess,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _compactCurrency(expense),
                          style: const TextStyle(
                            color: AppColors.statusDanger,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _compactCurrency(profit.abs()),
                          style: TextStyle(
                            color: profit >= 0
                                ? AppColors.statusSuccess
                                : AppColors.statusDanger,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),
      ],
    );
  }

  String _monthAbbr(String ym) {
    // expects "2025-01" or just month number
    final parts = ym.split('-');
    final month = int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 0;
    const abbr = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return month > 0 && month <= 12 ? abbr[month] : ym;
  }

  String _compactCurrency(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  Widget _buildReceivablesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Piutang Belum Lunas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_receivables.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceReceivablesScreen(),
                  ),
                ),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(color: _roleColor, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_receivables.isEmpty)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(20),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.statusSuccess,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Tidak ada piutang outstanding',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...(_receivables.take(3).map((r) => _buildReceivableItem(r))),
      ],
    );
  }

  Widget _buildReceivableItem(dynamic r) {
    final name = r['consumer_name'] as String? ?? '-';
    final code = r['order_code'] as String? ?? '-';
    final amount = _toDouble(r['amount']);
    final days = (r['days_outstanding'] as int?) ?? 0;

    Color chipColor;
    if (days >= 30) {
      chipColor = AppColors.statusDanger;
    } else if (days >= 14) {
      chipColor = AppColors.statusWarning;
    } else {
      chipColor = AppColors.statusInfo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currency.format(amount),
                  style: const TextStyle(
                    color: AppColors.statusDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$days hari',
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidWagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upah Tukang Jaga Belum Dibayar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_unpaidWages.isEmpty)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 10,
            tint: AppColors.statusSuccess.withValues(alpha: 0.05),
            borderColor: AppColors.statusSuccess.withValues(alpha: 0.2),
            padding: const EdgeInsets.all(20),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.statusSuccess,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Semua upah sudah dibayar ✓',
                  style: TextStyle(
                    color: AppColors.statusSuccess,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_unpaidWages.map((w) => _buildWageItem(w))),
      ],
    );
  }

  Widget _buildWageItem(dynamic w) {
    final name = w['tukang_jaga_name'] as String? ?? '-';
    final wage = _toDouble(w['wage']);
    final checkoutAt = w['checkout_at'] as String?;
    String dateStr = '-';
    if (checkoutAt != null) {
      final dt = DateTime.tryParse(checkoutAt);
      if (dt != null) dateStr = _dateFormat.format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.person_outline, color: _roleColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Checkout: $dateStr',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _currency.format(wage),
              style: const TextStyle(
                color: AppColors.statusWarning,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceReportScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text(
                  'Laporan Bulanan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceTransactionScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text(
                  'Semua Transaksi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // v1.40: Reminder pembayaran H+4..H+10
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentReminderScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.statusWarning.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.schedule_outlined, size: 18, color: AppColors.statusWarning),
            label: const Text(
              'Reminder Pembayaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.statusWarning,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showCashPaidDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.statusSuccess.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.statusSuccess),
            label: const Text(
              'Tandai Cash Lunas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.statusSuccess),
            ),
          ),
        ),
      ],
    );
  }

  void _showCashPaidDialog() {
    final orderIdCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.backgroundSoft,
          title: const Text('Tandai Cash Lunas',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan ID atau nomor order cash yang sudah dibayar tunai.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderIdCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Order ID',
                  prefixIcon: Icon(Icons.tag, color: AppColors.textHint, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusSuccess),
              onPressed: isSaving
                  ? null
                  : () async {
                      final id = orderIdCtrl.text.trim();
                      if (id.isEmpty) return;
                      setDialog(() => isSaving = true);
                      try {
                        await _apiClient.dio.post('/finance/orders/$id/cash-paid');
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order ditandai lunas (cash).'),
                              backgroundColor: AppColors.statusSuccess,
                            ),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        setDialog(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal menandai lunas. Periksa ID order.')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tandai Lunas'),
            ),
          ],
        ),
      ),
    );
  }
}
