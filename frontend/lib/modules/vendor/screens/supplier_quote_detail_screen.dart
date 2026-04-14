import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierQuoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> quote;

  const SupplierQuoteDetailScreen({super.key, required this.quote});

  @override
  State<SupplierQuoteDetailScreen> createState() =>
      _SupplierQuoteDetailScreenState();
}

class _SupplierQuoteDetailScreenState
    extends State<SupplierQuoteDetailScreen> {
  final _api = ApiClient();
  bool _isCancelling = false;
  late Map<String, dynamic> _quote;

  static const _roleColor = AppColors.roleSupplier;

  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _quote = Map<String, dynamic>.from(widget.quote);
  }

  Future<void> _cancelQuote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Penawaran?'),
        content: const Text(
          'Penawaran ini akan dibatalkan dan tidak dapat diajukan ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
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
      final res = await _api.dio
          .put('/supplier/supplier-quotes/${_quote['id']}/cancel');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _quote['status'] = 'cancelled');
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

  Color _statusColor(String s) => switch (s) {
        'accepted' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'pending' => AppColors.statusWarning,
        'cancelled' => AppColors.textHint,
        _ => AppColors.textSecondary,
      };

  String _statusLabel(String s) => switch (s) {
        'accepted' => 'Diterima',
        'rejected' => 'Ditolak',
        'pending' => 'Menunggu',
        'cancelled' => 'Dibatalkan',
        _ => s,
      };

  IconData _statusIcon(String s) => switch (s) {
        'accepted' => Icons.check_circle_rounded,
        'rejected' => Icons.cancel_rounded,
        'pending' => Icons.hourglass_empty_rounded,
        'cancelled' => Icons.block_rounded,
        _ => Icons.info_outline_rounded,
      };

  String _fmt(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _fmtPrice(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '');
    if (d == null) return v?.toString() ?? '-';
    return _currency.format(d);
  }

  @override
  Widget build(BuildContext context) {
    final po = Map<String, dynamic>.from(_quote['purchase_order'] ?? {});
    final status = _quote['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';

    final aiReasonable = po['ai_is_reasonable'] as bool?;
    final aiVariance = po['ai_price_variance_pct'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Penawaran',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            GlassWidget(
              borderRadius: 20,
              blurSigma: 16,
              tint: _statusColor(status).withValues(alpha: 0.06),
              borderColor: _statusColor(status).withValues(alpha: 0.20),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(status).withValues(alpha: 0.12),
                    ),
                    child: Icon(_statusIcon(status),
                        color: _statusColor(status), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusLabel(status),
                            style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          po['item_name'] ?? 'Item',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _section('Permintaan Barang', [
              _row(Icons.inventory_2_outlined, 'Nama Barang',
                  po['item_name'] ?? '-'),
              _row(Icons.numbers_rounded, 'Kuantitas',
                  '${po['quantity'] ?? '-'} ${po['unit'] ?? ''}'),
              if (po['proposed_price'] != null)
                _row(Icons.attach_money, 'Estimasi Harga',
                    _fmtPrice(po['proposed_price'])),
              if (po['notes'] != null && (po['notes'] as String).isNotEmpty)
                _row(Icons.notes_outlined, 'Catatan', po['notes']),
            ]),
            const SizedBox(height: 14),

            _section('Penawaran Anda', [
              _row(Icons.payments_outlined, 'Harga Ditawar',
                  _fmtPrice(_quote['quote_price'])),
              if (_quote['delivery_days'] != null)
                _row(Icons.local_shipping_outlined, 'Estimasi Pengiriman',
                    '${_quote['delivery_days']} hari'),
              if (_quote['quote_notes'] != null &&
                  (_quote['quote_notes'] as String).isNotEmpty)
                _row(Icons.notes_outlined, 'Catatan', _quote['quote_notes']),
              _row(Icons.calendar_today_outlined, 'Dikirim pada',
                  _fmt(_quote['created_at'])),
              if (_quote['updated_at'] != _quote['created_at'])
                _row(Icons.update_rounded, 'Diperbarui',
                    _fmt(_quote['updated_at'])),
            ]),
            const SizedBox(height: 14),

            if (aiReasonable != null) ...[
              GlassWidget(
                borderRadius: 16,
                blurSigma: 16,
                tint: aiReasonable
                    ? AppColors.statusSuccess.withValues(alpha: 0.06)
                    : AppColors.statusWarning.withValues(alpha: 0.06),
                borderColor: aiReasonable
                    ? AppColors.statusSuccess.withValues(alpha: 0.18)
                    : AppColors.statusWarning.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      aiReasonable
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: aiReasonable
                          ? AppColors.statusSuccess
                          : AppColors.statusWarning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aiReasonable
                                ? 'Harga Wajar (AI Terverifikasi)'
                                : 'Perlu Perhatian (AI)',
                            style: TextStyle(
                              color: aiReasonable
                                  ? AppColors.statusSuccess
                                  : AppColors.statusWarning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (aiVariance != null)
                            Text(
                              'Deviasi harga: ${(aiVariance as num).toStringAsFixed(1)}% dari referensi pasar',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (isAccepted) ...[
              GlassWidget(
                borderRadius: 16,
                blurSigma: 16,
                tint: AppColors.statusWarning.withValues(alpha: 0.06),
                borderColor: AppColors.statusWarning.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: AppColors.statusWarning, size: 20),
                        SizedBox(width: 8),
                        Text('Penawaran Diterima!',
                            style: TextStyle(
                                color: AppColors.statusWarning,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan siapkan barang sesuai spesifikasi. Tim Purchasing akan menghubungi Anda untuk koordinasi pengiriman.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (_quote['supplier_rating'] != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Rating Anda: ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (_quote['supplier_rating'] as num).round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.statusWarning,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _quote['supplier_rating'].toString(),
                            style: const TextStyle(
                                color: AppColors.statusWarning, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

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
                child: Text(
                  'Pembatalan tidak dapat dibatalkan kembali.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
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
