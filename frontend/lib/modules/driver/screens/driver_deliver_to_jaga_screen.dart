import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class DriverDeliverToJagaScreen extends StatefulWidget {
  final String orderId;
  final String orderCode;

  const DriverDeliverToJagaScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<DriverDeliverToJagaScreen> createState() =>
      _DriverDeliverToJagaScreenState();
}

class _ItemRow {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController unitCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _DriverDeliverToJagaScreenState
    extends State<DriverDeliverToJagaScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final List<_ItemRow> _items = [];
  bool _isSending = false;

  static const _roleColor = AppColors.roleDriver;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_ItemRow()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu item.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final itemsData = _items.map((r) => {
            'item_name': r.nameCtrl.text.trim(),
            'quantity': int.tryParse(r.qtyCtrl.text.trim()) ?? 0,
            'unit': r.unitCtrl.text.trim(),
          }).toList();

      final res = await _api.dio.post(
        '/driver/orders/${widget.orderId}/deliver-to-jaga',
        data: {
          'items': itemsData,
          'notes': _notesCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil dikirim ke tukang jaga!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog(res.data['message'] ?? 'Pengiriman gagal.');
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractErrorMessage(e);
        _showErrorDialog(msg);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _extractErrorMessage(dynamic e) {
    try {
      final resp = (e as dynamic).response;
      if (resp != null && resp.data is Map) {
        return resp.data['message'] ?? 'Terjadi kesalahan.';
      }
    } catch (_) {}
    return 'Terjadi kesalahan. Periksa koneksi Anda.';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pengiriman Gagal'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Kirim Barang ke Tukang Jaga',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order info header
            GlassWidget(
              borderRadius: 16,
              blurSigma: 12,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_outlined,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Order: ${widget.orderCode}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Items section
            Row(
              children: [
                const Text(
                  'Daftar Barang',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Item'),
                  style: TextButton.styleFrom(
                    foregroundColor: _roleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _buildItemRow(i, item);
            }),

            if (_items.isEmpty)
              GlassWidget(
                borderRadius: 12,
                blurSigma: 8,
                tint: AppColors.glassWhite,
                borderColor: AppColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text('Belum ada item. Tekan "Tambah Item".',
                      style: TextStyle(color: AppColors.textHint)),
                ),
              ),

            const SizedBox(height: 20),

            // Notes
            const Text(
              'Catatan (opsional)',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan catatan pengiriman...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.glassWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: const Text(
                  'KIRIM SEKARANG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, _ItemRow item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (_items.length > 1)
                  GestureDetector(
                    onTap: () => _removeItem(index),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.statusDanger, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: item.nameCtrl,
              decoration: _inputDecoration('Nama Barang'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Jumlah'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (int.tryParse(v.trim()) == null) return 'Angka';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.unitCtrl,
                    decoration: _inputDecoration('Satuan (pcs, buah, dll)'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusDanger),
        ),
      );
}
