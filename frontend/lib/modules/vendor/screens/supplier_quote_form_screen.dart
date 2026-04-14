import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierQuoteFormScreen extends StatefulWidget {
  final Map<String, dynamic> purchaseOrder;

  const SupplierQuoteFormScreen({super.key, required this.purchaseOrder});

  @override
  State<SupplierQuoteFormScreen> createState() =>
      _SupplierQuoteFormScreenState();
}

class _SupplierQuoteFormScreenState extends State<SupplierQuoteFormScreen> {
  final SupplierRepository _repository = SupplierRepository(ApiClient());
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedPhoto;
  bool _isSubmitting = false;

  static const _roleColor = AppColors.roleSupplier;

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        _showError(
            'Tidak dapat memilih foto. Pastikan izin kamera/galeri diberikan.');
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.textSecondary),
              title: const Text('Ambil Foto',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.textSecondary),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) {
      _showError('Masukkan harga yang valid.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quoteResp = await _repository.createSupplierQuote(
        widget.purchaseOrder['id'].toString(),
        price,
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      if (quoteResp.data['success'] != true) {
        _showError(quoteResp.data['message'] ?? 'Gagal mengirim penawaran.');
        return;
      }

      final quoteId = quoteResp.data['data']['id']?.toString();

      if (_selectedPhoto != null && quoteId != null) {
        try {
          await _repository.uploadQuotePhoto(quoteId, _selectedPhoto!);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Penawaran tersimpan, namun gagal upload foto. Coba lagi dari detail penawaran.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penawaran berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
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
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.statusDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.purchaseOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Ajukan Penawaran',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary
              GlassWidget(
                borderRadius: 16,
                blurSigma: 16,
                tint: _roleColor.withValues(alpha: 0.06),
                borderColor: _roleColor.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['item_name'] ?? 'Barang',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.inventory_2_outlined,
                        'Jumlah: ${order['quantity']} ${order['unit']}'),
                    const SizedBox(height: 4),
                    _infoRow(Icons.attach_money,
                        'Harga estimasi: ${order['proposed_price']}'),
                    if (order['max_price'] != null) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.price_check,
                          'Batas maks: Rp ${order['max_price']}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _fieldLabel('Harga Penawaran (Rp)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Contoh: 150000',
                  prefixIcon: Icon(Icons.payments_outlined,
                      color: AppColors.textHint, size: 20),
                  labelText: 'Harga Penawaran (Rp)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Harga wajib diisi.';
                  }
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Format harga tidak valid.';
                  }
                  final maxPrice = double.tryParse(
                    widget.purchaseOrder['max_price']?.toString() ?? '',
                  );
                  if (maxPrice != null && parsed > maxPrice) {
                    return 'Melebihi batas maksimum Rp ${maxPrice.toStringAsFixed(0)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _fieldLabel('Catatan (opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Spesifikasi, syarat pengiriman, garansi…',
                  labelText: 'Catatan',
                ),
              ),
              const SizedBox(height: 24),

              _fieldLabel('Foto Produk (opsional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: _selectedPhoto != null
                    ? _photoPreview()
                    : _photoPlaceholder(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kirim Penawaran',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: AppColors.textHint, size: 40),
            SizedBox(height: 8),
            Text('Ketuk untuk menambah foto produk',
                style:
                    TextStyle(color: AppColors.textHint, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _photoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            _selectedPhoto!,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedPhoto = null),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: _showPhotoSourceSheet,
            child: Container(
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: const Text('Ganti',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: TextStyle(
            color: _roleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      );
}
