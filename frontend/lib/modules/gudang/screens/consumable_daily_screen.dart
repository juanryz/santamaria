import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class ConsumableDailyScreen extends StatefulWidget {
  final String orderId;
  const ConsumableDailyScreen({super.key, required this.orderId});

  @override
  State<ConsumableDailyScreen> createState() => _ConsumableDailyScreenState();
}

class _ConsumableDailyScreenState extends State<ConsumableDailyScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _entries = [];
  List<dynamic> _masterItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/orders/${widget.orderId}/consumables'),
        _api.dio.get('/admin/master/consumables'),
      ]);
      if (results[0].data['success'] == true) {
        _entries = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _masterItems = List<dynamic>.from(results[1].data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addEntry() async {
    String selectedShift = 'pagi';
    final qtyControllers = <String, TextEditingController>{};
    for (final m in _masterItems) {
      qtyControllers[m['id']] = TextEditingController(text: '0');
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Input Data Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedShift,
                  decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pagi', child: Text('Pagi (P)')),
                    DropdownMenuItem(value: 'kirim', child: Text('Kirim (K)')),
                    DropdownMenuItem(value: 'malam', child: Text('Malam (M)')),
                  ],
                  onChanged: (v) => setModalState(() => selectedShift = v!),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _masterItems.length,
                    itemBuilder: (_, i) {
                      final m = _masterItems[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('${m['item_name']} (${m['unit']})', style: const TextStyle(fontSize: 13))),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: qtyControllers[m['id']],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.roleGudang, minimumSize: const Size.fromHeight(48)),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final lines = <Map<String, dynamic>>[];
      for (final m in _masterItems) {
        final qty = int.tryParse(qtyControllers[m['id']]?.text ?? '0') ?? 0;
        if (qty > 0) {
          lines.add({'consumable_master_id': m['id'], 'qty': qty});
        }
      }

      if (lines.isNotEmpty) {
        try {
          await _api.dio.post('/orders/${widget.orderId}/consumables', data: {
            'consumable_date': DateTime.now().toIso8601String().split('T')[0],
            'shift': selectedShift,
            'lines': lines,
          });
          _loadData();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }

    for (final c in qtyControllers.values) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Data Barang Konsumabel', accentColor: AppColors.roleGudang),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roleGudang,
        onPressed: _addEntry,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? const Center(child: Text('Belum ada data konsumabel'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      final lines = List<dynamic>.from(e['lines'] ?? []);
                      final shiftLabel = {'pagi': 'Pagi', 'kirim': 'Kirim', 'malam': 'Malam'}[e['shift']] ?? e['shift'];
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
                                    Text('${e['consumable_date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.roleGudang.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                      child: Text(shiftLabel, style: TextStyle(fontSize: 12, color: AppColors.roleGudang, fontWeight: FontWeight.w600)),
                                    ),
                                    if (e['is_retur'] == true) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('RETUR', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...lines.map((l) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(l['master']?['item_name'] ?? '-', style: const TextStyle(fontSize: 12))),
                                          Text('${l['qty']} ${l['master']?['unit'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    )),
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
