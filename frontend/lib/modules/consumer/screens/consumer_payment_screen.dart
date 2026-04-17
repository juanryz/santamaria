import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isLoadingBilling = true;
  String _paymentMethod = 'transfer';
  File? _proofImage;
  final ImagePicker _picker = ImagePicker();
  static const _roleColor = AppColors.roleConsumer;

  // Billing items from API
  List<dynamic> _billingItems = [];
  double _grandTotal = 0;

  // Payment status from order
  String _paymentStatus = 'unpaid'; // unpaid, proof_uploaded, paid, proof_rejected

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    setState(() => _isLoadingBilling = true);
    try {
      Response<dynamic>? billingRes;
      Response<dynamic>? statusRes;

      try {
        billingRes = await _api.dio.get('/orders/${widget.orderId}/billing');
      } catch (_) {}
      try {
        statusRes = await _api.dio.get('/consumer/orders/${widget.orderId}/payment-status');
      } catch (_) {}

      // Billing items
      if (billingRes?.data != null) {
        final data = billingRes!.data;
        if (data is Map && data['data'] is List) {
          _billingItems = List<dynamic>.from(data['data']);
        } else if (data is Map && data['items'] is List) {
          _billingItems = List<dynamic>.from(data['items']);
        }
      }

      // Payment status
      if (statusRes?.data is Map) {
        final d = statusRes!.data as Map;
        _paymentStatus = d['data']?['payment_status']?.toString() ??
            d['payment_status']?.toString() ??
            'unpaid';
      }

      // Calculate grand total from billing items or fallback to widget.totalPrice
      if (_billingItems.isNotEmpty) {
        _grandTotal = _billingItems.fold<double>(0, (sum, item) {
          final total = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
          return sum + total;
        });
      } else {
        _grandTotal = widget.totalPrice;
      }
    } catch (_) {
      _grandTotal = widget.totalPrice;
    }
    if (mounted) setState(() => _isLoadingBilling = false);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
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
        await _api.dio.post(
          '/consumer/orders/${widget.orderId}/payment-proof',
          data: {'payment_method': 'cash'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_paymentMethod == 'transfer'
              ? 'Bukti transfer berhasil diupload. Menunggu verifikasi.'
              : 'Pembayaran cash dicatat. Menunggu konfirmasi kasir.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _downloadInvoice() async {
    final baseUrl = _api.dio.options.baseUrl;
    final url = '$baseUrl/consumer/orders/${widget.orderId}/invoice';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka invoice: $e')),
        );
      }
    }
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get _isPaid => _paymentStatus == 'paid' || _paymentStatus == 'verified';
  bool get _isProofUploaded => _paymentStatus == 'proof_uploaded';
  bool get _isProofRejected => _paymentStatus == 'proof_rejected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Pembayaran', accentColor: _roleColor),
      body: _isLoadingBilling
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Payment status badge
                _buildStatusBadge(),
                const SizedBox(height: 16),

                // Order info + Grand total
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
                          _formatCurrency(_grandTotal),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _roleColor),
                        ),
                        const SizedBox(height: 4),
                        Text('Total Tagihan', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice items
                if (_billingItems.isNotEmpty) ...[
                  _buildInvoiceSection(),
                  const SizedBox(height: 12),
                ],

                // Download invoice PDF
                OutlinedButton.icon(
                  onPressed: _downloadInvoice,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Download Invoice PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _roleColor,
                    side: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),

                // If already paid, show access button
                if (_isPaid) ...[
                  _buildPaidSection(),
                ] else ...[
                  // If proof rejected, show reason
                  if (_isProofRejected) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.statusDanger, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'Bukti pembayaran ditolak. Silakan upload ulang.',
                            style: TextStyle(color: AppColors.statusDanger, fontSize: 13),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // If proof already uploaded and waiting, show waiting message
                  if (_isProofUploaded) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.statusInfo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusInfo.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top, color: AppColors.statusInfo, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'Bukti pembayaran sudah dikirim. Menunggu verifikasi.',
                            style: TextStyle(color: AppColors.statusInfo, fontSize: 13),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // Payment method selector (only if not already proof_uploaded)
                  if (!_isProofUploaded) ...[
                    const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _methodCard(
                          icon: Icons.account_balance,
                          label: 'Transfer Bank',
                          value: 'transfer',
                          isSelected: _paymentMethod == 'transfer',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _methodCard(
                          icon: Icons.payments,
                          label: 'Cash',
                          value: 'cash',
                          isSelected: _paymentMethod == 'cash',
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cash: info text
                    if (_paymentMethod == 'cash') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(child: Text(
                              'Pembayaran cash akan dikonfirmasi oleh petugas Santa Maria.',
                              style: TextStyle(fontSize: 13),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Transfer: upload proof
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

                    // Submit button
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
                ],

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildStatusBadge() {
    final (String label, Color color, IconData icon) = switch (_paymentStatus) {
      'paid' || 'verified' => ('Lunas', AppColors.statusSuccess, Icons.check_circle),
      'proof_uploaded'     => ('Bukti Dikirim', AppColors.statusInfo, Icons.hourglass_top),
      'proof_rejected'     => ('Bukti Ditolak', AppColors.statusDanger, Icons.cancel),
      _                    => ('Belum Bayar', AppColors.statusPending, Icons.pending),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text('Status: $label', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    return GlassWidget(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rincian Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ..._billingItems.map((item) {
              final name = item['item_name']?.toString() ?? item['billing_master']?['item_name']?.toString() ?? '-';
              final qty = item['qty']?.toString() ?? '1';
              final total = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
                    Text('x$qty', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(_formatCurrency(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(_formatCurrency(_grandTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _roleColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _ratingDismissed = false;

  Widget _buildPaidSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.statusSuccess.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.3)),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 48),
              SizedBox(height: 10),
              Text('Pembayaran Lunas', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.statusSuccess,
              )),
              SizedBox(height: 4),
              Text('Terima kasih atas kepercayaan Anda.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            // Navigate to gallery/docs screen
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.photo_library),
          label: const Text('Akses Foto & Dokumen'),
          style: FilledButton.styleFrom(
            backgroundColor: _roleColor,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        // Rating prompt
        if (!_ratingDismissed) ...[
          const SizedBox(height: 20),
          _buildRatingPrompt(),
        ],
      ],
    );
  }

  Widget _buildRatingPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Text(
            'Terima kasih telah memilih\nSanta Maria',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bantu kami menjadi lebih baik:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _launchExternalUrl('https://play.google.com/store/apps/details?id=com.santamaria.app'),
            icon: const Icon(Icons.star_rate_rounded, size: 20),
            label: const Text('Rate di Google Play'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _launchExternalUrl('https://maps.app.goo.gl/santamaria-semarang'),
            icon: const Icon(Icons.location_on_rounded, size: 20),
            label: const Text('Review di Google Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandSecondary,
              side: BorderSide(color: AppColors.brandSecondary.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _ratingDismissed = true),
            child: const Text('Nanti saja', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
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
