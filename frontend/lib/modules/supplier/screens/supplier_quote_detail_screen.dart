import 'dart:io';
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierQuoteDetailScreen extends StatefulWidget {
  final String quoteId;

  const SupplierQuoteDetailScreen({super.key, required this.quoteId});

  @override
  State<SupplierQuoteDetailScreen> createState() =>
      _SupplierQuoteDetailScreenState();
}

class _SupplierQuoteDetailScreenState
    extends State<SupplierQuoteDetailScreen> {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isShipping = false;
  Map<String, dynamic>? _quote;

  static const _roleColor = AppColors.roleSupplier;

  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/supplier/quotes/${widget.quoteId}');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _quote = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat detail penawaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelQuote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Penawaran?'),
        content: const Text(
            'Penawaran ini akan dibatalkan dan tidak dapat diajukan ulang.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final res =
          await _api.dio.put('/supplier/quotes/${widget.quoteId}/cancel');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _quote!['status'] = 'cancelled';
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penawaran berhasil dibatalkan.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membatalkan penawaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _markShipped() async {
    final resiCtrl = TextEditingController();
    File? shipPhoto;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tandai Sudah Dikirim'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: resiCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nomor Resi (opsional)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(
                  shipPhoto != null ? Icons.check : Icons.camera_alt_outlined,
                  size: 16),
              label: Text(shipPhoto != null ? 'Foto dipilih' : 'Foto Paket (opsional)'),
              onPressed: () async {
                final picked = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 85);
                if (picked != null) {
                  setDialogState(() => shipPhoto = File(picked.path));
                }
              },
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'tracking_number': resiCtrl.text.trim(),
                'photo': shipPhoto,
              }),
              child: const Text('Konfirmasi Kirim'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isShipping = true);
    try {
      final data = <String, dynamic>{};
      if ((result['tracking_number'] as String).isNotEmpty) {
        data['tracking_number'] = result['tracking_number'];
      }
      if (result['photo'] != null) {
        data['shipment_photo'] = await MultipartFile.fromFile(
            (result['photo'] as File).path,
            filename: 'shipment.jpg');
      }

      if (data.isNotEmpty) {
        await _api.dio.put(
          '/supplier/quotes/${widget.quoteId}/mark-shipped',
          data: data.containsKey('shipment_photo')
              ? FormData.fromMap(data)
              : data,
        );
      } else {
        await _api.dio
            .put('/supplier/quotes/${widget.quoteId}/mark-shipped');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Berhasil ditandai dikirim.'),
              backgroundColor: AppColors.statusSuccess),
        );
        _loadDetail();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai pengiriman.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isShipping = false);
    }
  }

  Color _statusColor(String s) => switch (s) {
        'submitted' => AppColors.statusPending,
        'under_review' => AppColors.statusInfo,
        'awarded' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'cancelled' => AppColors.textHint,
        'shipped' => AppColors.brandAccent,
        'completed' => AppColors.statusSuccess,
        _ => AppColors.textSecondary,
      };

  String _statusLabel(String s) => switch (s) {
        'submitted' => 'Menunggu Review',
        'under_review' => 'Sedang Dievaluasi',
        'awarded' => 'Terpilih',
        'rejected' => 'Tidak Dipilih',
        'cancelled' => 'Dibatalkan',
        'shipped' => 'Sudah Dikirim',
        'completed' => 'Selesai',
        _ => s,
      };

  IconData _statusIcon(String s) => switch (s) {
        'submitted' => Icons.hourglass_empty_rounded,
        'under_review' => Icons.search_rounded,
        'awarded' => Icons.emoji_events_rounded,
        'rejected' => Icons.cancel_rounded,
        'cancelled' => Icons.block_rounded,
        'shipped' => Icons.local_shipping_rounded,
        'completed' => Icons.check_circle_rounded,
        _ => Icons.info_outline_rounded,
      };

  String _fmt(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
  }

  String _fmtPrice(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '');
    if (d == null) return v?.toString() ?? '-';
    return _currency.format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Penawaran',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
              ? const Center(
                  child: Text('Data tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final q = _quote!;
    final request =
        q['procurement_request'] as Map<String, dynamic>? ??
            q['purchase_order'] as Map<String, dynamic>? ??
            {};
    final status = q['status'] as String? ?? 'submitted';
    final isPending = status == 'submitted';
    final isAwarded = status == 'awarded';
    final sColor = _statusColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          GlassWidget(
            borderRadius: 20,
            blurSigma: 16,
            tint: sColor.withValues(alpha: 0.06),
            borderColor: sColor.withValues(alpha: 0.20),
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sColor.withValues(alpha: 0.12),
                ),
                child: Icon(_statusIcon(status), color: sColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusLabel(status),
                        style: TextStyle(
                            color: sColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(request['item_name'] ?? 'Item',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Status timeline
          _section('Status Timeline', [
            _timelineStep('Penawaran Dikirim', _fmt(q['created_at']), true),
            _timelineStep(
                'Sedang Dievaluasi',
                status == 'submitted' ? 'Menunggu...' : _fmt(q['updated_at']),
                ['under_review', 'awarded', 'shipped', 'completed']
                    .contains(status)),
            if (isAwarded || status == 'shipped' || status == 'completed')
              _timelineStep('Terpilih', _fmt(q['awarded_at'] ?? q['updated_at']), true),
            if (status == 'shipped' || status == 'completed')
              _timelineStep('Dikirim', _fmt(q['shipped_at'] ?? q['updated_at']), true),
            if (status == 'completed')
              _timelineStep('Selesai', _fmt(q['completed_at'] ?? q['updated_at']), true),
            if (status == 'rejected')
              _timelineStep('Tidak Dipilih', _fmt(q['updated_at']), true),
            if (status == 'cancelled')
              _timelineStep('Dibatalkan', _fmt(q['updated_at']), true),
          ]),
          const SizedBox(height: 14),

          // Request info
          _section('Permintaan Barang', [
            _row(Icons.inventory_2_outlined, 'Nama Barang',
                request['item_name'] ?? '-'),
            _row(Icons.numbers_rounded, 'Kuantitas',
                '${request['quantity'] ?? '-'} ${request['unit'] ?? ''}'),
            if (request['max_price'] != null)
              _row(Icons.price_check, 'Batas Harga',
                  _fmtPrice(request['max_price'])),
          ]),
          const SizedBox(height: 14),

          // My quote info
          _section('Penawaran Anda', [
            _row(Icons.payments_outlined, 'Harga per Unit',
                _fmtPrice(q['unit_price'] ?? q['quote_price'])),
            if (q['total_price'] != null)
              _row(Icons.receipt_outlined, 'Total Harga',
                  _fmtPrice(q['total_price'])),
            if (q['brand'] != null)
              _row(Icons.branding_watermark_outlined, 'Merek', q['brand']),
            if (q['description'] != null && (q['description'] as String).isNotEmpty)
              _row(Icons.description_outlined, 'Deskripsi', q['description']),
            if (q['estimated_delivery_days'] != null)
              _row(Icons.local_shipping_outlined, 'Estimasi Pengiriman',
                  '${q['estimated_delivery_days']} hari'),
            if (q['warranty_info'] != null)
              _row(Icons.verified_user_outlined, 'Garansi', q['warranty_info']),
            _row(Icons.calendar_today_outlined, 'Dikirim pada',
                _fmt(q['created_at'])),
          ]),
          const SizedBox(height: 14),

          // Awarded: delivery instructions
          if (isAwarded) ...[
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.statusSuccess.withValues(alpha: 0.06),
              borderColor: AppColors.statusSuccess.withValues(alpha: 0.18),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.emoji_events_rounded,
                        color: AppColors.statusSuccess, size: 20),
                    SizedBox(width: 8),
                    Text('Penawaran Anda Terpilih!',
                        style: TextStyle(
                            color: AppColors.statusSuccess,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                      'Silakan segera kirimkan barang sesuai spesifikasi.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  if (request['delivery_address'] != null) ...[
                    const SizedBox(height: 8),
                    _row(Icons.location_on_outlined, 'Kirim ke',
                        request['delivery_address']),
                  ],
                  if (request['needed_by'] != null)
                    _row(Icons.timer_outlined, 'Batas kirim',
                        _fmtDate(request['needed_by'])),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isShipping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.local_shipping_rounded, size: 18),
                label: Text(
                    _isShipping ? 'Memproses...' : 'Tandai Sudah Dikirim',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isShipping ? null : _markShipped,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Shipped info
          if (status == 'shipped') ...[
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.brandAccent.withValues(alpha: 0.06),
              borderColor: AppColors.brandAccent.withValues(alpha: 0.18),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.local_shipping_rounded,
                        color: AppColors.brandAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Barang Sudah Dikirim',
                        style: TextStyle(
                            color: AppColors.brandAccent,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  if (q['tracking_number'] != null)
                    _row(Icons.confirmation_number_outlined, 'Nomor Resi',
                        q['tracking_number']),
                  const Text(
                      'Menunggu konfirmasi penerimaan dari Gudang.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Cancel button for pending
          if (isPending) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelQuote,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(
                    _isCancelling ? 'Membatalkan...' : 'Batalkan Penawaran'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusDanger,
                  side: const BorderSide(color: AppColors.statusDanger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Pembatalan tidak dapat dibatalkan kembali.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _timelineStep(String label, String time, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.statusSuccess
                    : AppColors.textHint.withValues(alpha: 0.3),
              ),
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(time,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) => GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}
