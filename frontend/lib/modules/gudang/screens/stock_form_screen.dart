import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Formulir Pengambilan & Pengembalian Barang
class StockFormScreen extends StatefulWidget {
  final String? orderId;
  const StockFormScreen({super.key, this.orderId});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  static const _roleColor = AppColors.roleGudang;

  List<dynamic> _stockItems = [];
  String? _selectedStockId;
  String _formType = 'pengambilan';
  final _qtyCtrl = TextEditingController();
  final _picNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  Future<void> _loadStockItems() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/stock');
      if (res.data['success'] == true) {
        _stockItems = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedStockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua field')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _api.dio.post('/gudang/stock/form', data: {
        'stock_item_id': _selectedStockId,
        'form_type': _formType,
        'quantity': double.parse(_qtyCtrl.text),
        'order_id': widget.orderId,
        'pic_name': _picNameCtrl.text.isNotEmpty ? _picNameCtrl.text : null,
        'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      });

      if (res.data['success'] == true && mounted) {
        final msg = res.data['message'] ?? 'Berhasil';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _formType == 'pengambilan' ? 'Pengambilan Barang' : 'Pengembalian Barang',
        accentColor: _roleColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Form type toggle
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip('Pengambilan', 'pengambilan', Icons.arrow_upward, Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _typeChip('Pengembalian', 'pengembalian', Icons.arrow_downward, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  GlassWidget(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Stock item dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStockId,
                            decoration: const InputDecoration(labelText: 'Pilih Barang *', border: OutlineInputBorder()),
                            items: _stockItems.map((s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text('${s['item_name']} (stok: ${s['current_quantity']} ${s['unit']})', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedStockId = v),
                            validator: (v) => v == null ? 'Wajib pilih' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _qtyCtrl,
                            decoration: const InputDecoration(labelText: 'Jumlah *', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi';
                              if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Harus > 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _picNameCtrl,
                            decoration: const InputDecoration(labelText: 'Nama PIC / Pengambil', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _formType == 'pengambilan' ? Colors.red.shade700 : Colors.green.shade700,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_formType == 'pengambilan' ? 'Ambil Barang' : 'Kembalikan Barang'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _typeChip(String label, String value, IconData icon, Color color) {
    final isSelected = _formType == value;
    return GestureDetector(
      onTap: () => setState(() => _formType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _picNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
