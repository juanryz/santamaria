import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';

const Map<String, String> _categoryLabels = {
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

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({super.key});

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  final ApiClient _apiClient = ApiClient();

  final int _currentYear = DateTime.now().year;
  late int _selectedYear;
  int? _selectedMonth; // null = all year

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _roleColor = AppColors.roleFinance;

  @override
  void initState() {
    super.initState();
    _selectedYear = _currentYear;
    _selectedMonth = DateTime.now().month;
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final params = <String, dynamic>{'year': _selectedYear};
      if (_selectedMonth != null) params['month'] = _selectedMonth;

      final res = await _apiClient.dio.get('/finance/reports/summary', queryParameters: params);
      if (!mounted) return;
      setState(() {
        _summary = (res.data['data'] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat laporan. Periksa koneksi Anda.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportReport(String format) async {
    final params = StringBuffer('?type=monthly_summary&year=$_selectedYear');
    if (_selectedMonth != null) params.write('&month=$_selectedMonth');
    params.write('&format=$format');

    final baseUrl = _apiClient.dio.options.baseUrl;
    final url = Uri.parse('${baseUrl}finance/reports/export$params');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka URL export.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal export laporan.')),
        );
      }
    }
  }

  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _categoryLabel(String key) => _categoryLabels[key] ?? key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  @override
  Widget build(BuildContext context) {
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
          'Laporan Keuangan',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            else if (_error != null)
              _buildError()
            else if (_summary != null) ...[
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildCategoryTable('Pendapatan per Kategori', _summary!['income_by_category']),
              const SizedBox(height: 20),
              _buildCategoryTable('Pengeluaran per Kategori', _summary!['expense_by_category']),
              const SizedBox(height: 24),
              _buildExportButtons(),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final years = [_currentYear, _currentYear - 1, _currentYear - 2];
    const months = [
      null,
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
    ];
    const monthNames = [
      'Semua Tahun',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periode Laporan', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropdown<int>(
                  value: _selectedYear,
                  items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedYear = v); },
                  label: 'Tahun',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown<int?>(
                  value: _selectedMonth,
                  items: List.generate(months.length, (i) => DropdownMenuItem(
                    value: months[i],
                    child: Text(monthNames[i], style: const TextStyle(fontSize: 13)),
                  )),
                  onChanged: (v) => setState(() => _selectedMonth = v),
                  label: 'Bulan',
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _fetchReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Tampilkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.expand_more, color: AppColors.textHint, size: 18),
        ),
      ),
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
          const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 36),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchReport,
            style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final income = _toDouble(_summary!['total_income']);
    final expense = _toDouble(_summary!['total_expense']);
    final profit = _toDouble(_summary!['net_profit'] ?? (income - expense));
    final orderCount = _summary!['order_count'] ?? 0;
    final avgOrder = _toDouble(_summary!['average_order_value']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryCard('Pendapatan Total', _currency.format(income), AppColors.statusSuccess, Icons.trending_up)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Pengeluaran Total', _currency.format(expense), AppColors.statusDanger, Icons.trending_down)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryCard(
              'Laba Bersih',
              _currency.format(profit.abs()),
              profit >= 0 ? AppColors.statusSuccess : AppColors.statusDanger,
              profit >= 0 ? Icons.account_balance_wallet : Icons.money_off,
              prefix: profit < 0 ? '-' : '',
            )),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Jumlah Order', orderCount.toString(), AppColors.roleFinance, Icons.receipt_long)),
          ],
        ),
        if (_selectedMonth != null && avgOrder > 0) ...[
          const SizedBox(height: 10),
          _summaryCard('Rata-rata Nilai Order', _currency.format(avgOrder), AppColors.brandAccent, Icons.calculate),
        ],
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon, {String prefix = ''}) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prefix$value', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTable(String title, dynamic rawData) {
    if (rawData == null) return const SizedBox.shrink();
    final Map<String, dynamic> data = rawData is Map ? Map<String, dynamic>.from(rawData) : {};
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold<double>(0, (sum, v) => sum + _toDouble(v));
    final sorted = data.entries.toList()..sort((a, b) => _toDouble(b.value).compareTo(_toDouble(a.value)));

    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(flex: 4, child: Text('Kategori', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 4, child: Text('Jumlah', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('%', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 12),
          ...sorted.map((e) {
            final amt = _toDouble(e.value);
            final pct = total > 0 ? (amt / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(_categoryLabel(e.key), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                  Expanded(flex: 4, child: Text(_currency.format(amt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                  Expanded(flex: 2, child: Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textHint, fontSize: 11))),
                ],
              ),
            );
          }),
          const Divider(height: 12),
          Row(
            children: [
              const Expanded(flex: 4, child: Text('Total', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 4, child: Text(_currency.format(total), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('100%', style: TextStyle(color: AppColors.textHint, fontSize: 11))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportReport('pdf'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
              side: const BorderSide(color: AppColors.statusDanger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportReport('xlsx'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusSuccess,
              side: const BorderSide(color: AppColors.statusSuccess),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
