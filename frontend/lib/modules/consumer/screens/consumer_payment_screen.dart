import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import 'package:dio/dio.dart';

class ConsumerPaymentScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final double totalPrice;

  const ConsumerPaymentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalPrice,
  });

  @override
  State<ConsumerPaymentScreen> createState() => _ConsumerPaymentScreenState();
}

class _ConsumerPaymentScreenState extends State<ConsumerPaymentScreen> {
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;
  String _paymentMethod = 'transfer'; // 'cash' or 'transfer'
  File? _proofImage;
  final ImagePicker _picker = ImagePicker();
  static const _roleColor = AppColors.roleConsumer;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80, // Compress to ~5MB max per pedoman
    );

    if (picked != null) {
      final file = File(picked.path);
      final sizeBytes = await file.length();
      final sizeMB = sizeBytes / (1024 * 1024);

      if (sizeMB > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran foto maksimal 5MB. Silakan pilih foto lain.')),
          );
        }
        return;
      }

      setState(() => _proofImage = file);
    }
  }

  Future<void> _submit() async {
    if (_paymentMethod == 'transfer' && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload bukti transfer terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_paymentMethod == 'transfer' && _proofImage != null) {
        final formData = FormData.fromMap({
          'payment_method': 'transfer',
          'payment_proof': await MultipartFile.fromFile(
            _proofImage!.path,
            filename: 'payment_proof_${widget.orderId}.jpg',
          ),
        });

        await _api.dio.post(
          '/consumer/orders/${widget.orderId}/payment-proof',
          data: formData,
        );
      } else {
        // Cash payment — just mark as cash
        await _api.dio.post(
          '/consumer/orders/${widget.orderId}/payment-proof',
          data: {'payment_method': 'cash'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_paymentMethod == 'transfer'
              ? 'Bukti transfer berhasil diupload. Menunggu verifikasi Purchasing.'
              : 'Pembayaran cash dicatat. Purchasing akan mengonfirmasi.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Pembayaran', accentColor: _roleColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Info
          GlassWidget(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(widget.totalPrice),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _roleColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Payment Method
          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _methodCard(
                  icon: Icons.account_balance,
                  label: 'Transfer Bank',
                  value: 'transfer',
                  isSelected: _paymentMethod == 'transfer',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _methodCard(
                  icon: Icons.payments,
                  label: 'Cash',
                  value: 'cash',
                  isSelected: _paymentMethod == 'cash',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Proof upload (transfer only)
          if (_paymentMethod == 'transfer') ...[
            const Text('Upload Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _proofImage != null ? _roleColor : Colors.grey.shade300,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  color: Colors.grey.shade50,
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_proofImage!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap untuk pilih foto', style: TextStyle(color: Colors.grey.shade500)),
                          Text('Maksimal 5MB', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Submit
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _roleColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _paymentMethod == 'transfer' ? 'Upload Bukti Transfer' : 'Konfirmasi Pembayaran Cash',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _methodCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _roleColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? _roleColor.withValues(alpha: 0.08) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _roleColor : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _roleColor : Colors.grey,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }
}
