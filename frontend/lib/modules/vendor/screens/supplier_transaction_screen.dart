import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/dynamic_status_badge.dart';

class SupplierTransactionScreen extends StatefulWidget {
  const SupplierTransactionScreen({super.key});

  @override
  State<SupplierTransactionScreen> createState() => _SupplierTransactionScreenState();
}

class _SupplierTransactionScreenState extends State<SupplierTransactionScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/supplier/transactions');
      if (res.data['success'] == true) {
        _transactions = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markShipped(String quoteId) async {
    final resiCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Sudah Dikirim'),
        content: TextField(controller: resiCtrl, decoration: const InputDecoration(labelText: 'Nomor Resi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
        ],
      ),
    );

    if (result == true) {
      try {
        await _api.dio.put('/supplier/quotes/$quoteId/mark-shipped', data: {
          'tracking_number': resiCtrl.text,
        });
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil ditandai dikirim')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _confirmPayment(String transactionId) async {
    try {
      await _api.dio.put('/supplier/transactions/$transactionId/confirm-payment');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran dikonfirmasi')));
    } catch (_) {}
  }

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Transaksi Saya', accentColor: _roleColor),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (_, i) {
                      final t = _transactions[i];
                      final shipStatus = t['shipment_status'] ?? '';
                      final payStatus = t['payment_status'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassWidget(
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(t['transaction_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DynamicStatusBadge(enumGroup: 'procurement_status', value: payStatus),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Barang: ${t['procurement_request']?['item_name'] ?? '-'}'),
                                Text('Qty: ${t['agreed_quantity']} | Total: ${_formatCurrency(t['agreed_total'])}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Pengiriman: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    DynamicStatusBadge(enumGroup: 'procurement_status', value: shipStatus),
                                  ],
                                ),
                                if (t['tracking_number'] != null)
                                  Text('Resi: ${t['tracking_number']}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (shipStatus == 'pending_shipment')
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _markShipped(t['supplier_quote_id'] ?? ''),
                                          icon: const Icon(Icons.local_shipping, size: 16),
                                          label: const Text('Tandai Dikirim'),
                                          style: FilledButton.styleFrom(backgroundColor: _roleColor),
                                        ),
                                      ),
                                    if (payStatus == 'paid' && shipStatus == 'goods_received')
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _confirmPayment(t['id']),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Konfirmasi Terima Bayaran'),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
