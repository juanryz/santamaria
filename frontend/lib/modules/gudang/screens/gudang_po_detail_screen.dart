import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/gudang_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class GudangPODetailScreen extends StatefulWidget {
  final String poId;
  const GudangPODetailScreen({super.key, required this.poId});

  @override
  State<GudangPODetailScreen> createState() => _GudangPODetailScreenState();
}

class _GudangPODetailScreenState extends State<GudangPODetailScreen> {
  final GudangRepository _repository = GudangRepository(ApiClient());
  bool _isLoading = true;
  Map<String, dynamic> _po = {};
  List<dynamic> _quotes = [];
  String? _processingQuoteId;

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response =
          await _repository.getPurchaseOrderDetail(widget.poId);
      if (!mounted) return;
      if (response.data['success'] == true) {
        final data =
            Map<String, dynamic>.from(response.data['data'] ?? {});
        setState(() {
          _po = data;
          _quotes =
              List<dynamic>.from(data['supplier_quotes'] ?? []);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Gagal memuat detail Purchase Order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptQuote(
      String quoteId, String supplierName, String price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terima Penawaran?'),
        content: Text(
            'Terima penawaran dari $supplierName dengan harga Rp $price?\n\nPenawaran lain akan otomatis dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSuccess),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingQuoteId = quoteId);
    try {
      final response = await _repository.acceptQuote(quoteId);
      if (!mounted) return;
      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Penawaran berhasil diterima. Finance telah dinotifikasi.')),
        );
        await _loadDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.data['message'] ??
                  'Gagal menerima penawaran.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menerima penawaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingQuoteId = null);
    }
  }

  Future<void> _rejectQuote(
      String quoteId, String supplierName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Penawaran?'),
        content: Text('Tolak penawaran dari $supplierName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingQuoteId = quoteId);
    try {
      final response = await _repository.rejectQuote(quoteId);
      if (!mounted) return;
      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penawaran berhasil ditolak.')),
        );
        await _loadDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.data['message'] ??
                  'Gagal menolak penawaran.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menolak penawaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingQuoteId = null);
    }
  }

  Color _poStatusColor(String s) => switch (s) {
        'completed' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'pending_ai' => AppColors.statusWarning,
        'pending_finance' => Colors.amber,
        'approved_finance' || 'approved_owner_override' => AppColors.roleConsumer,
        'anomaly_pending_owner' => Colors.deepOrange,
        _ => AppColors.textHint,
      };

  String _poStatusLabel(String s) => switch (s) {
        'pending_ai' => 'Validasi AI',
        'pending_finance' => 'Menunggu Finance',
        'anomaly_pending_owner' => 'Anomali – Menunggu Owner',
        'approved_finance' => 'Disetujui Finance',
        'approved_owner_override' => 'Disetujui Owner',
        'rejected' => 'Ditolak',
        'completed' => 'Selesai',
        _ => s,
      };

  Color _quoteStatusColor(String s) => switch (s) {
        'accepted' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'cancelled' => AppColors.textHint,
        'pending' => AppColors.statusWarning,
        _ => AppColors.textHint,
      };

  String _quoteStatusLabel(String s) => switch (s) {
        'accepted' => 'Diterima',
        'rejected' => 'Ditolak',
        'cancelled' => 'Dibatalkan',
        'pending' => 'Menunggu',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final poStatus = _po['status'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Purchase Order',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PO Info Card
                    GlassWidget(
                      borderRadius: 20,
                      blurSigma: 16,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _po['item_name'] ?? 'Item',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (poStatus.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _poStatusColor(poStatus)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _poStatusLabel(poStatus),
                                style: TextStyle(
                                    color: _poStatusColor(poStatus),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          _infoRow('Jumlah',
                              '${_po['quantity'] ?? '-'} ${_po['unit'] ?? ''}'),
                          _infoRow('Harga Estimasi',
                              'Rp ${_po['proposed_price'] ?? '-'}'),
                          if (_po['market_price'] != null)
                            _infoRow('Harga Pasar',
                                'Rp ${_po['market_price']}'),
                          if (_po['is_anomaly'] == true)
                            _infoRow('Anomali',
                                'Ya – Perlu persetujuan owner'),
                          if (_po['supplier_name'] != null)
                            _infoRow('Supplier Dipilih',
                                _po['supplier_name'] as String),
                          if (_po['ai_analysis'] != null) ...[
                            const SizedBox(height: 10),
                            const Text('Analisis AI:',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              _po['ai_analysis'] as String,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quotes section
                    Row(
                      children: [
                        const Text('Penawaran Supplier',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_quotes.length}',
                            style: const TextStyle(
                                color: _roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_quotes.isEmpty)
                      GlassWidget(
                        borderRadius: 16,
                        blurSigma: 16,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(20),
                        child: const Row(
                          children: [
                            Icon(Icons.inbox_outlined,
                                color: AppColors.textHint),
                            SizedBox(width: 12),
                            Text('Belum ada penawaran masuk.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ..._quotes.map((q) => _buildQuoteCard(
                          Map<String, dynamic>.from(q))),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final quoteId = quote['id'] as String? ?? '';
    final status = quote['status'] as String? ?? 'pending';
    final supplier =
        Map<String, dynamic>.from(quote['supplier'] ?? {});
    final supplierName =
        supplier['name'] as String? ?? 'Tidak diketahui';
    final price = quote['quote_price']?.toString() ?? '-';
    final notes = quote['quote_notes'] as String?;
    final isPending = status == 'pending';
    final isProcessing = _processingQuoteId == quoteId;
    final aiReasonable = quote['ai_is_reasonable'] as bool?;
    final aiVariance = quote['ai_price_variance_pct'];
    final supplierRating = supplier['supplier_rating'] ?? 0;
    final qsc = _quoteStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    color: AppColors.textHint, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(supplierName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: qsc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_quoteStatusLabel(status),
                      style: TextStyle(
                          color: qsc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Rp $price',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (supplierRating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        (supplierRating as num).toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            if (aiReasonable != null) ...[
              const SizedBox(height: 8),
              _aiBadge(aiReasonable, aiVariance),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Catatan: $notes',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _rejectQuote(quoteId, supplierName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(
                            color: AppColors.statusDanger),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Tolak',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _acceptQuote(
                              quoteId, supplierName, price),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Terima',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _aiBadge(bool reasonable, dynamic variance) {
    final isAnomaly =
        variance != null && (variance as num).abs() > 20;
    final color = reasonable
        ? AppColors.statusSuccess
        : isAnomaly
            ? AppColors.statusDanger
            : AppColors.statusWarning;
    final label = reasonable
        ? 'Harga Wajar'
        : isAnomaly
            ? 'Anomali Harga'
            : 'Perlu Perhatian';
    final icon = reasonable
        ? Icons.auto_awesome
        : Icons.warning_amber_rounded;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color)),
          if (variance != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${(variance as num) > 0 ? '+' : ''}${variance.toStringAsFixed(1)}%)',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}
