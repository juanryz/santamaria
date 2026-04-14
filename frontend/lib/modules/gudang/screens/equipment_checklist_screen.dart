import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class EquipmentChecklistScreen extends StatefulWidget {
  final String orderId;
  const EquipmentChecklistScreen({super.key, required this.orderId});

  @override
  State<EquipmentChecklistScreen> createState() => _EquipmentChecklistScreenState();
}

class _EquipmentChecklistScreenState extends State<EquipmentChecklistScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/orders/${widget.orderId}/equipment');
      if (res.data['success'] == true) {
        _items = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendItem(String itemId) async {
    try {
      await _api.dio.put('/gudang/orders/${widget.orderId}/equipment/$itemId/send');
      _loadData();
    } catch (_) {}
  }

  Future<void> _returnItem(String itemId, int qtySent) async {
    final ctrl = TextEditingController(text: '$qtySent');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jumlah Dikembalikan'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)), child: const Text('Konfirmasi')),
        ],
      ),
    );

    if (result != null) {
      try {
        await _api.dio.put('/gudang/orders/${widget.orderId}/equipment/$itemId/return', data: {'qty_returned': result});
        _loadData();
      } catch (_) {}
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'prepared': return Colors.grey;
      case 'sent': return Colors.blue;
      case 'received': return Colors.teal;
      case 'returned': return Colors.green;
      case 'partial_return': return Colors.orange;
      case 'missing': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Peralatan Order', accentColor: AppColors.roleGudang),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('Belum ada peralatan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final status = item['status'] ?? 'prepared';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item['item_description'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    GlassStatusBadge(label: status, color: _statusColor(status)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Kategori: ${item['category'] ?? '-'} | Kode: ${item['item_code'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text('Kirim: ${item['qty_sent']} | Terima: ${item['qty_received']} | Kembali: ${item['qty_returned']}'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (status == 'prepared')
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _sendItem(item['id']),
                                          icon: const Icon(Icons.send, size: 16),
                                          label: const Text('Kirim'),
                                        ),
                                      ),
                                    if (status == 'sent' || status == 'received') ...[
                                      if (status == 'prepared') const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _returnItem(item['id'], item['qty_sent'] ?? 0),
                                          icon: const Icon(Icons.assignment_return, size: 16),
                                          label: const Text('Kembali'),
                                        ),
                                      ),
                                    ],
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
