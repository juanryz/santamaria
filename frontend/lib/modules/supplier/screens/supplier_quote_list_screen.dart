import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_quote_detail_screen.dart';

class SupplierQuoteListScreen extends StatefulWidget {
  const SupplierQuoteListScreen({super.key});

  @override
  State<SupplierQuoteListScreen> createState() =>
      _SupplierQuoteListScreenState();
}

class _SupplierQuoteListScreenState extends State<SupplierQuoteListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _quotes = [];

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/supplier/quotes');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _quotes = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat penawaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) => switch (status) {
        'submitted' => AppColors.statusPending,
        'under_review' => AppColors.statusInfo,
        'awarded' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'cancelled' => AppColors.textHint,
        'shipped' => AppColors.brandAccent,
        'completed' => AppColors.statusSuccess,
        _ => AppColors.textSecondary,
      };

  String _statusLabel(String status) => switch (status) {
        'submitted' => 'Menunggu',
        'under_review' => 'Dievaluasi',
        'awarded' => 'Terpilih',
        'rejected' => 'Tidak Dipilih',
        'cancelled' => 'Dibatalkan',
        'shipped' => 'Dikirim',
        'completed' => 'Selesai',
        _ => status,
      };

  IconData _statusIcon(String status) => switch (status) {
        'submitted' => Icons.hourglass_empty_rounded,
        'under_review' => Icons.search_rounded,
        'awarded' => Icons.emoji_events_rounded,
        'rejected' => Icons.cancel_rounded,
        'cancelled' => Icons.block_rounded,
        'shipped' => Icons.local_shipping_rounded,
        'completed' => Icons.check_circle_rounded,
        _ => Icons.info_outline_rounded,
      };

  String _fmtCurrency(dynamic value) {
    final d = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Penawaran Saya',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: _loadData,
            child: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? const Center(
                  child: Text('Belum ada penawaran terkirim.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quotes.length,
                    itemBuilder: (_, i) {
                      final q = _quotes[i];
                      final status = q['status'] as String? ?? 'submitted';
                      final request =
                          q['procurement_request'] as Map<String, dynamic>? ??
                              q['purchase_order'] as Map<String, dynamic>? ??
                              {};
                      final sColor = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: GlassWidget(
                          borderRadius: 20,
                          blurSigma: 16,
                          tint: sColor.withValues(alpha: 0.04),
                          borderColor: sColor.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SupplierQuoteDetailScreen(
                                    quoteId: q['id'].toString()),
                              ),
                            );
                            _loadData();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(
                                    request['item_name'] ?? 'Penawaran',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            sColor.withValues(alpha: 0.30)),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_statusIcon(status),
                                            size: 12, color: sColor),
                                        const SizedBox(width: 4),
                                        Text(_statusLabel(status),
                                            style: TextStyle(
                                                color: sColor,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ]),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  'Harga: ${_fmtCurrency(q['unit_price'] ?? q['quote_price'])}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              if (q['total_price'] != null)
                                Text('Total: ${_fmtCurrency(q['total_price'])}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textHint, size: 14),
                                const SizedBox(width: 4),
                                const Text('Ketuk untuk detail',
                                    style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
