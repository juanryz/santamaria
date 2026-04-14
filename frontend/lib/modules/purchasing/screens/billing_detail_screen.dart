import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class BillingDetailScreen extends StatefulWidget {
  final String orderId;
  const BillingDetailScreen({super.key, required this.orderId});

  @override
  State<BillingDetailScreen> createState() => _BillingDetailScreenState();
}

class _BillingDetailScreenState extends State<BillingDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isExporting = false;
  List<dynamic> _items = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/orders/${widget.orderId}/billing');
      if (res.data['success'] == true) {
        _items = List<dynamic>.from(res.data['data'] ?? []);
        _summary = Map<String, dynamic>.from(res.data['summary'] ?? {});
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/purchasing/billing/export/${widget.orderId}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka PDF. Coba lagi.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal export PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Laporan Tagihan',
        accentColor: AppColors.rolePurchasing,
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.rolePurchasing),
                  tooltip: 'Export PDF',
                  onPressed: _exportPdf,
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
                  // Summary card
                  GlassWidget(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _summaryRow('Total Layanan', _formatCurrency(_summary['total'])),
                          _summaryRow('Tambahan', _formatCurrency(_summary['totalTambahan'])),
                          _summaryRow('Kembali', '- ${_formatCurrency(_summary['totalKembali'])}'),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GRAND TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(_formatCurrency(_summary['grandTotal']),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.rolePurchasing)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Item list header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Items
                  ..._items.map((item) {
                    final source = item['source'] ?? 'package';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['billing_master']?['item_name'] ?? '-', style: const TextStyle(fontSize: 13)),
                                if (source != 'package')
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: source == 'manual' ? Colors.orange.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(source, style: TextStyle(fontSize: 10, color: source == 'manual' ? Colors.orange : Colors.blue)),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(child: Text('${item['qty']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text(_formatCurrency(item['total_price']), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
