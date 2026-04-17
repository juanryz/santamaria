import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierTransactionScreen extends StatefulWidget {
  const SupplierTransactionScreen({super.key});

  @override
  State<SupplierTransactionScreen> createState() =>
      _SupplierTransactionScreenState();
}

class _SupplierTransactionScreenState
    extends State<SupplierTransactionScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  static const _roleColor = AppColors.roleSupplier;

  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/supplier/transactions');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _transactions = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat transaksi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPayment(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text(
            'Apakah Anda sudah menerima pembayaran di rekening Anda?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Belum')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Sudah Terima')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.dio
          .put('/supplier/transactions/$transactionId/confirm-payment');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembayaran dikonfirmasi.'),
            backgroundColor: AppColors.statusSuccess));
        _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengkonfirmasi.')),
        );
      }
    }
  }

  String _fmtPrice(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '');
    if (d == null) return v?.toString() ?? '-';
    return _currency.format(d);
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
  }

  Color _shipColor(String s) => switch (s) {
        'pending_shipment' => AppColors.statusWarning,
        'shipped' => AppColors.statusInfo,
        'goods_received' => AppColors.statusSuccess,
        'partial_received' => AppColors.brandAccent,
        _ => AppColors.textSecondary,
      };

  String _shipLabel(String s) => switch (s) {
        'pending_shipment' => 'Menunggu Pengiriman',
        'shipped' => 'Sudah Dikirim',
        'goods_received' => 'Barang Diterima',
        'partial_received' => 'Diterima Sebagian',
        _ => s,
      };

  Color _payColor(String s) => switch (s) {
        'unpaid' => AppColors.statusWarning,
        'paid' => AppColors.statusSuccess,
        _ => AppColors.textSecondary,
      };

  String _payLabel(String s) => switch (s) {
        'unpaid' => 'Belum Dibayar',
        'paid' => 'Sudah Dibayar',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Transaksi Saya',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: _loadData,
            child: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Text('Belum ada transaksi.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (_, i) => _buildCard(_transactions[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final shipStatus = t['shipment_status'] as String? ?? '';
    final payStatus = t['payment_status'] as String? ?? '';
    final request =
        t['procurement_request'] as Map<String, dynamic>? ?? {};
    final canConfirmPay =
        payStatus == 'paid' && !(t['payment_confirmed_by_supplier'] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Text(t['transaction_number'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              _badge(_payLabel(payStatus), _payColor(payStatus)),
            ]),
            const SizedBox(height: 8),

            Text(request['item_name'] ?? '-',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),

            Row(children: [
              const Icon(Icons.inventory_2_outlined,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text('Qty: ${t['agreed_quantity'] ?? '-'}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.payments_outlined,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text('Total: ${_fmtPrice(t['agreed_total'])}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ]),
            const SizedBox(height: 8),

            // Shipment status
            Row(children: [
              const Text('Pengiriman: ',
                  style:
                      TextStyle(color: AppColors.textHint, fontSize: 12)),
              _badge(_shipLabel(shipStatus), _shipColor(shipStatus)),
            ]),

            if (t['tracking_number'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: AppColors.textHint, size: 12),
                const SizedBox(width: 4),
                Text('Resi: ${t['tracking_number']}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ],

            if (t['payment_date'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textHint, size: 12),
                const SizedBox(width: 4),
                Text('Dibayar: ${_fmtDate(t['payment_date'])}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ],

            if (canConfirmPay) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmPayment(t['id'].toString()),
                  icon:
                      const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Konfirmasi Terima Pembayaran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusSuccess,
                    side: const BorderSide(
                        color: AppColors.statusSuccess),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}
