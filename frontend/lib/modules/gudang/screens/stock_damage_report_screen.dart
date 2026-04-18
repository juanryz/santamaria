import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/screens/barcode_scanner_screen.dart';

/// v1.39 — Laporkan barang rusak via barcode scan.
class StockDamageReportScreen extends StatefulWidget {
  const StockDamageReportScreen({super.key});

  @override
  State<StockDamageReportScreen> createState() =>
      _StockDamageReportScreenState();
}

class _StockDamageReportScreenState extends State<StockDamageReportScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _stockItem;
  String? _scannedBarcode;
  final _qtyCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _damageLevel = 'minor';
  String? _responsibleParty;
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _lossCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;

    try {
      final res = await _api.dio
          .post('/gudang/stock/scan', data: {'barcode': code});
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() {
          _scannedBarcode = code;
          _stockItem = Map<String, dynamic>.from(
              res.data['data']['stock_item'] ?? {});
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Barcode tidak ditemukan'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal resolve barcode'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Future<void> _submit() async {
    if (_stockItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Scan barcode dulu'),
            backgroundColor: AppColors.statusWarning),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.dio.post('/gudang/stock/damage-logs', data: {
        'stock_item_id': _stockItem!['id'],
        'barcode_scanned': _scannedBarcode,
        'quantity_damaged': num.tryParse(_qtyCtrl.text) ?? 0,
        'damage_level': _damageLevel,
        'estimated_loss_amount': num.tryParse(_lossCtrl.text) ?? 0,
        'damage_description': _descCtrl.text.trim(),
        if (_responsibleParty != null)
          'responsible_party': _responsibleParty,
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Laporan kerusakan tersimpan'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal menyimpan'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyimpan laporan'),
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
        title: 'Lapor Barang Rusak',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan button / item preview
            if (_stockItem == null)
              GlassWidget(
                padding: const EdgeInsets.all(24),
                tint: AppColors.roleGudang.withOpacity(0.08),
                borderColor: AppColors.roleGudang.withOpacity(0.3),
                onTap: _scanBarcode,
                child: Column(
                  children: const [
                    Icon(Icons.qr_code_scanner,
                        size: 48, color: AppColors.roleGudang),
                    SizedBox(height: 12),
                    Text('Scan Barcode Stok',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 6),
                    Text(
                      'Arahkan kamera ke barcode pada item',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              _stockItemCard(),
            const SizedBox(height: 16),

            if (_stockItem != null) ...[
              _label('Tingkat Kerusakan'),
              DropdownButtonFormField<String>(
                value: _damageLevel,
                decoration: _dec(Icons.warning),
                items: const [
                  DropdownMenuItem(value: 'minor', child: Text('Minor')),
                  DropdownMenuItem(value: 'moderate', child: Text('Sedang')),
                  DropdownMenuItem(value: 'severe', child: Text('Parah')),
                  DropdownMenuItem(
                      value: 'total_loss', child: Text('Total (Tak Terpakai)')),
                ],
                onChanged: (v) => setState(() => _damageLevel = v ?? 'minor'),
              ),
              const SizedBox(height: 12),

              _label('Jumlah Rusak'),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(Icons.numbers,
                    suffix: _stockItem?['unit'] ?? ''),
                validator: (v) {
                  final n = num.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Masukkan jumlah > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _label('Estimasi Kerugian (Rp)'),
              TextFormField(
                controller: _lossCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec(Icons.payments),
                validator: (v) {
                  final n = num.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Masukkan nominal';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _label('Pihak Bertanggung Jawab (opsional)'),
              DropdownButtonFormField<String>(
                value: _responsibleParty,
                isExpanded: true,
                decoration: _dec(Icons.person),
                items: const [
                  DropdownMenuItem(value: null, child: Text('—')),
                  DropdownMenuItem(
                      value: 'sm_gudang', child: Text('SM - Gudang')),
                  DropdownMenuItem(
                      value: 'sm_driver', child: Text('SM - Driver')),
                  DropdownMenuItem(value: 'sm_dekor', child: Text('SM - Dekor')),
                  DropdownMenuItem(
                      value: 'tukang_jaga', child: Text('Tukang Jaga')),
                  DropdownMenuItem(value: 'keluarga', child: Text('Keluarga')),
                  DropdownMenuItem(
                      value: 'unknown', child: Text('Tidak Diketahui')),
                ],
                onChanged: (v) => setState(() => _responsibleParty = v),
              ),
              const SizedBox(height: 12),

              _label('Deskripsi Kerusakan'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _dec(Icons.notes,
                    hint: 'Jelaskan kondisi & penyebab kerusakan'),
                validator: (v) {
                  if ((v ?? '').trim().length < 10) {
                    return 'Deskripsi minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusDanger,
                    minimumSize: const Size.fromHeight(48)),
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.warning_amber),
                label: Text(_saving ? 'Menyimpan…' : 'Simpan Laporan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stockItemCard() {
    final name = _stockItem?['item_name'] ?? '-';
    final code = _stockItem?['item_code'] ?? '-';
    final qty = num.tryParse('${_stockItem?['current_quantity']}') ?? 0;
    final unit = _stockItem?['unit'] ?? '';

    return GlassWidget(
      padding: const EdgeInsets.all(14),
      tint: AppColors.statusSuccess.withOpacity(0.08),
      borderColor: AppColors.statusSuccess.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.statusSuccess, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('$code · stok: $qty $unit',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace')),
                if (_scannedBarcode != null)
                  Text('Scanned: $_scannedBarcode',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Scan ulang',
            onPressed: () {
              setState(() {
                _stockItem = null;
                _scannedBarcode = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(s,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  InputDecoration _dec(IconData icon, {String? hint, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}
