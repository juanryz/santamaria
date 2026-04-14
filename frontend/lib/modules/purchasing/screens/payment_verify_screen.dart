import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class PaymentVerifyScreen extends StatefulWidget {
  const PaymentVerifyScreen({super.key});

  @override
  State<PaymentVerifyScreen> createState() => _PaymentVerifyScreenState();
}

class _PaymentVerifyScreenState extends State<PaymentVerifyScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/finance/consumer-payments/pending');
      if (res.data['success'] == true) {
        _payments = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _verify(String orderId) async {
    try {
      await _api.dio.put('/finance/consumer-payments/$orderId/verify');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment diverifikasi')));
    } catch (_) {}
  }

  Future<void> _reject(String orderId) async {
    final reason = await _showReasonDialog();
    if (reason == null || reason.isEmpty) return;
    try {
      await _api.dio.put('/finance/consumer-payments/$orderId/reject', data: {'reason': reason});
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment ditolak')));
    } catch (_) {}
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Masukkan alasan...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Tolak')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Verifikasi Payment', accentColor: AppColors.rolePurchasing),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _payments.isEmpty
                ? const Center(child: Text('Tidak ada payment menunggu verifikasi'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (_, i) {
                      final p = _payments[i];
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
                                    Expanded(child: Text(p['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    GlassStatusBadge(label: p['payment_status'] ?? '', color: Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Konsumen: ${p['consumer']?['name'] ?? '-'}'),
                                Text('Paket: ${p['package']?['name'] ?? '-'}'),
                                if (p['total_price'] != null) Text('Total: Rp ${p['total_price']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                if (p['payment_proof_path'] != null)
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade200,
                                    ),
                                    child: const Center(child: Icon(Icons.receipt_long, size: 48, color: Colors.grey)),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _reject(p['id']),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _verify(p['id']),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Verifikasi'),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
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
