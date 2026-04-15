import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';

class FinanceReceivablesScreen extends StatefulWidget {
  const FinanceReceivablesScreen({super.key});

  @override
  State<FinanceReceivablesScreen> createState() => _FinanceReceivablesScreenState();
}

class _FinanceReceivablesScreenState extends State<FinanceReceivablesScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _receivables = [];

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _roleColor = AppColors.roleFinance;

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
      final res = await _apiClient.dio.get('/finance/receivables');
      if (!mounted) return;
      final data = res.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      }
      setState(() {
        _receivables = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data piutang.';
          _isLoading = false;
        });
      }
    }
  }

  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  Color _daysColor(int days) {
    if (days >= 30) return AppColors.statusDanger;
    if (days >= 14) return AppColors.statusWarning;
    return AppColors.statusInfo;
  }

  @override
  Widget build(BuildContext context) {
    final totalOutstanding = _receivables.fold<double>(
      0,
      (sum, r) => sum + _toDouble(r['amount']),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Piutang Belum Lunas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _receivables.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Summary card
                          GlassWidget(
                            borderRadius: 16,
                            blurSigma: 10,
                            tint: AppColors.statusDanger.withValues(alpha: 0.05),
                            borderColor: AppColors.statusDanger.withValues(alpha: 0.2),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusDanger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.statusDanger, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currency.format(totalOutstanding),
                                      style: const TextStyle(
                                        color: AppColors.statusDanger,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total dari ${_receivables.length} order',
                                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          Row(
                            children: [
                              _legendDot(AppColors.statusInfo, '< 14 hari'),
                              const SizedBox(width: 14),
                              _legendDot(AppColors.statusWarning, '14–29 hari'),
                              const SizedBox(width: 14),
                              _legendDot(AppColors.statusDanger, '≥ 30 hari'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // List
                          ..._receivables.map((r) => _buildReceivableCard(r)),
                        ],
                      ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildReceivableCard(dynamic r) {
    final name = r['consumer_name'] as String? ?? '-';
    final code = r['order_code'] as String? ?? '-';
    final amount = _toDouble(r['amount']);
    final days = (r['days_outstanding'] as int?) ?? 0;
    final dueDate = r['due_date'] as String?;
    final packageName = r['package_name'] as String?;
    final chipColor = _daysColor(days);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: chipColor.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$days hari',
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Kode Order', code),
            if (packageName != null) _infoRow('Paket', packageName),
            if (dueDate != null) _infoRow('Jatuh Tempo', _formatDate(dueDate)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _currency.format(amount),
                  style: const TextStyle(
                    color: AppColors.statusDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.statusSuccess, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada piutang outstanding',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua pembayaran telah lunas ✓',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
