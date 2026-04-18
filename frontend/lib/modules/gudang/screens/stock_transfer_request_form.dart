import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.40 — Form request transfer stok antar lokasi.
/// Gudang/Lafiore request ke Super Admin (kantor), atau sebaliknya.
class StockTransferRequestForm extends StatefulWidget {
  const StockTransferRequestForm({super.key});

  @override
  State<StockTransferRequestForm> createState() =>
      _StockTransferRequestFormState();
}

class _StockTransferRequestFormState extends State<StockTransferRequestForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  String _fromRole = 'super_admin';
  String _toRole = 'gudang';
  List<dynamic> _stockItems = [];
  Map<String, dynamic>? _selectedItem;
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isConsignment = false;
  final _batchCtrl = TextEditingController();
  List<dynamic> _suppliers = [];
  Map<String, dynamic>? _selectedSupplier;

  bool _loadingItems = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStockItems();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStockItems() async {
    setState(() => _loadingItems = true);
    try {
      // Ambil stok dari lokasi asal (from_role)
      final res = await _api.dio.get('/role-stock/items');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _stockItems = List<dynamic>.from(res.data['data'] ?? []));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingItems = false);
  }

  Future<void> _loadSuppliers() async {
    try {
      // Ambil suppliers (opsional, untuk consignment tracking)
      final res = await _api.dio.get('/admin/users?role=supplier');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _suppliers =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih item stok dulu'),
            backgroundColor: AppColors.statusWarning),
      );
      return;
    }
    if (_fromRole == _toRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Asal dan tujuan tidak boleh sama'),
            backgroundColor: AppColors.statusDanger),
      );
      return;
    }

    setState(() => _saving = true);

    final body = {
      'from_owner_role': _fromRole,
      'to_owner_role': _toRole,
      'stock_item_id': _selectedItem!['id'],
      'quantity': num.tryParse(_qtyCtrl.text) ?? 0,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_isConsignment && _selectedSupplier != null)
        'source_supplier_id': _selectedSupplier!['id'],
      if (_isConsignment && _batchCtrl.text.trim().isNotEmpty)
        'source_consignment_batch': _batchCtrl.text.trim(),
    };

    try {
      final res = await _api.dio.post('/stock-transfers', data: body);
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Request transfer tercatat'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal membuat request'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal membuat request transfer'),
            backgroundColor: AppColors.statusDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Request Transfer Stok',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Asal & Tujuan'),
            Row(
              children: [
                Expanded(child: _roleDropdown(_fromRole, (v) {
                  setState(() {
                    _fromRole = v;
                    _selectedItem = null;
                  });
                  _loadStockItems();
                }, 'Dari')),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        color: AppColors.textHint)),
                Expanded(
                    child: _roleDropdown(
                        _toRole, (v) => setState(() => _toRole = v), 'Ke')),
              ],
            ),
            const SizedBox(height: 16),

            _section('Item Stok'),
            if (_loadingItems)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stockItems.isEmpty)
              GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusWarning.withOpacity(0.1),
                borderColor: AppColors.statusWarning.withOpacity(0.3),
                child: const Text(
                  'Tidak ada stok di lokasi asal. Pastikan lokasi asal memiliki stok yang akan ditransfer.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                value: _selectedItem,
                decoration: _dec(icon: Icons.inventory_2, hint: 'Pilih item'),
                items: _stockItems
                    .map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                  final i = item as Map<String, dynamic>;
                  final name = i['item_name'] ?? '-';
                  final qty = i['current_quantity'] ?? 0;
                  final unit = i['unit'] ?? '';
                  return DropdownMenuItem(
                    value: i,
                    child: Text('$name — $qty $unit',
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedItem = v),
              ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec(
                icon: Icons.pin,
                hint: 'Jumlah yang diminta',
                suffix: _selectedItem?['unit'] ?? '',
              ),
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Masukkan jumlah';
                final avail = num.tryParse('${_selectedItem?['current_quantity']}') ?? 0;
                if (n > avail) {
                  return 'Melebihi stok tersedia ($avail)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // v1.40 — Consignment (barang titipan kacang)
            SwitchListTile(
              title: const Text('Barang Titipan Supplier',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Aktifkan jika ini barang titipan (misal: kacang dari supplier)',
                  style: TextStyle(fontSize: 12)),
              value: _isConsignment,
              onChanged: (v) => setState(() => _isConsignment = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isConsignment) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedSupplier,
                isExpanded: true,
                decoration: _dec(
                    icon: Icons.local_shipping, hint: 'Pilih supplier'),
                items: _suppliers
                    .map<DropdownMenuItem<Map<String, dynamic>>>((s) {
                  final m = s as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m['name'] ?? '-'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedSupplier = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batchCtrl,
                decoration: _dec(
                    icon: Icons.numbers,
                    hint: 'Batch / No. PO (opsional)'),
              ),
            ],
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _dec(
                  icon: Icons.notes, hint: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Mengirim…' : 'Kirim Request Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(s,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      );

  Widget _roleDropdown(String value, ValueChanged<String> onChanged, String label) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.backgroundSoft,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem(value: 'gudang', child: Text('Gudang')),
          DropdownMenuItem(value: 'super_admin', child: Text('Kantor')),
          DropdownMenuItem(value: 'dekor', child: Text('Lafiore')),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );

  InputDecoration _dec({IconData? icon, String? hint, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}
