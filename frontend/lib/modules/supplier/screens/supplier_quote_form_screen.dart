import 'dart:io';
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class SupplierQuoteFormScreen extends StatefulWidget {
  final Map<String, dynamic> procurementRequest;

  const SupplierQuoteFormScreen({super.key, required this.procurementRequest});

  @override
  State<SupplierQuoteFormScreen> createState() =>
      _SupplierQuoteFormScreenState();
}

class _SupplierQuoteFormScreenState extends State<SupplierQuoteFormScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _unitPriceCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deliveryDaysCtrl = TextEditingController();
  final _warrantyCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _photo;
  bool _isSubmitting = false;

  static const _roleColor = AppColors.roleSupplier;

  Map<String, dynamic> get _req => widget.procurementRequest;

  double get _quantity =>
      double.tryParse(_req['quantity']?.toString() ?? '0') ?? 0;

  double? get _maxPrice =>
      double.tryParse(_req['max_price']?.toString() ?? '');

  double get _totalPrice {
    final unitPrice =
        double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.')) ?? 0;
    return unitPrice * _quantity;
  }

  String _fmtCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  void dispose() {
    _unitPriceCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _deliveryDaysCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      }
    } catch (_) {
      if (mounted) _showError('Gagal memilih foto.');
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded,
                color: AppColors.textSecondary),
            title: const Text('Ambil Foto'),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppColors.textSecondary),
            title: const Text('Pilih dari Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final unitPrice =
        double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.'));
    if (unitPrice == null) {
      _showError('Masukkan harga yang valid.');
      return;
    }

    final total = unitPrice * _quantity;
    if (_maxPrice != null && total > _maxPrice!) {
      _showError(
          'Total harga (${_fmtCurrency(total)}) melebihi batas maksimum ${_fmtCurrency(_maxPrice!)}');
      return;
    }

    // Confirmation dialog
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Konfirmasi Penawaran',
      message: 'Harga per unit: ${_fmtCurrency(unitPrice)}\n'
          'Total: ${_fmtCurrency(total)}\n\n'
          'Penawaran tidak bisa diubah setelah dikirim. Lanjutkan?',
      confirmLabel: 'Kirim',
      confirmColor: _roleColor,
      icon: Icons.send,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final data = {
        'procurement_request_id': _req['id'].toString(),
        'unit_price': unitPrice,
        'total_price': total,
        'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'estimated_delivery_days':
            int.tryParse(_deliveryDaysCtrl.text.trim()),
        'warranty_info': _warrantyCtrl.text.trim().isEmpty
            ? null
            : _warrantyCtrl.text.trim(),
      };

      final res = await _api.dio.post('/supplier/quotes', data: data);
      if (!mounted) return;

      if (res.data['success'] != true) {
        _showError(res.data['message'] ?? 'Gagal mengirim penawaran.');
        return;
      }

      final quoteId = res.data['data']?['id']?.toString();

      // Upload photo if selected
      if (_photo != null && quoteId != null) {
        try {
          final formData = <String, dynamic>{
            'photo': await MultipartFile.fromFile(_photo!.path,
                filename: _photo!.path.split('/').last),
          };
          await _api.dio.post('/supplier/quotes/$quoteId/product-photo',
              data: FormData.fromMap(formData));
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Penawaran tersimpan, namun gagal upload foto.'),
                backgroundColor: Colors.orange));
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Penawaran berhasil dikirim!'),
            backgroundColor: AppColors.statusSuccess));
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.statusDanger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
          title: 'Ajukan Penawaran', accentColor: _roleColor, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request summary
              GlassWidget(
                borderRadius: 16,
                blurSigma: 16,
                tint: _roleColor.withValues(alpha: 0.06),
                borderColor: _roleColor.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_req['item_name'] ?? 'Barang',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _infoRow(Icons.inventory_2_outlined,
                        'Jumlah: ${_req['quantity']} ${_req['unit'] ?? ''}'),
                    if (_maxPrice != null) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.price_check,
                          'Batas maks: ${_fmtCurrency(_maxPrice!)}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _fieldLabel('Harga per Unit (Rp) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unitPriceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Contoh: 50000',
                    prefixIcon: Icon(Icons.payments_outlined,
                        color: AppColors.textHint, size: 20),
                    labelText: 'Harga per Unit'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi.';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Format tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Auto-calculated total
              GlassWidget(
                borderRadius: 12,
                blurSigma: 10,
                tint: _roleColor.withValues(alpha: 0.04),
                borderColor: _roleColor.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.calculate_outlined,
                      color: AppColors.textHint, size: 16),
                  const SizedBox(width: 8),
                  Text(
                      'Total: ${_fmtCurrency(_totalPrice)} (${_quantity.toStringAsFixed(0)} x harga/unit)',
                      style: TextStyle(
                          color: _roleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              if (_maxPrice != null && _totalPrice > _maxPrice!)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      'Total melebihi batas maksimum ${_fmtCurrency(_maxPrice!)}',
                      style: const TextStyle(
                          color: AppColors.statusDanger, fontSize: 12)),
                ),
              const SizedBox(height: 20),

              _fieldLabel('Merek / Brand'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Nama merek produk',
                    labelText: 'Merek'),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Deskripsi Produk'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Spesifikasi, material, keunggulan...',
                    labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Estimasi Hari Pengiriman *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deliveryDaysCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Contoh: 3',
                    prefixIcon: Icon(Icons.local_shipping_outlined,
                        color: AppColors.textHint, size: 20),
                    labelText: 'Estimasi Pengiriman (hari)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi.';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Masukkan angka.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _fieldLabel('Info Garansi (opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _warrantyCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Misal: Garansi 1 tahun',
                    labelText: 'Garansi'),
              ),
              const SizedBox(height: 24),

              _fieldLabel('Foto Produk (opsional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showPhotoSheet,
                child:
                    _photo != null ? _photoPreview() : _photoPlaceholder(),
              ),
              const SizedBox(height: 32),

              LoadingButton(
                label: 'Kirim Penawaran',
                loadingLabel: 'Mengirim...',
                isLoading: _isSubmitting,
                onPressed: _submit,
                color: _roleColor,
                icon: Icons.send,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: AppColors.textHint, size: 40),
            SizedBox(height: 8),
            Text('Ketuk untuk menambah foto produk',
                style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          ]),
        ),
      );

  Widget _photoPreview() => Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(_photo!,
              width: double.infinity, height: 180, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photo = null),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ]);

  Widget _fieldLabel(String text) => Text(text,
      style: TextStyle(
          color: _roleColor, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ]);
}

