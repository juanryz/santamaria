import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_quote_form_screen.dart';
import 'supplier_quote_detail_screen.dart';

class SupplierCatalogDetailScreen extends StatefulWidget {
  final String requestId;

  const SupplierCatalogDetailScreen({super.key, required this.requestId});

  @override
  State<SupplierCatalogDetailScreen> createState() =>
      _SupplierCatalogDetailScreenState();
}

class _SupplierCatalogDetailScreenState
    extends State<SupplierCatalogDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _request;

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio
          .get('/supplier/procurement-requests/${widget.requestId}');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _request = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat detail permintaan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtCurrency(dynamic value) {
    final d = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool get _deadlinePassed {
    final dl = _request?['quote_deadline'] as String?;
    if (dl == null) return false;
    final dt = DateTime.tryParse(dl);
    return dt != null && dt.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Permintaan',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(
                  child: Text('Data tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = _request!;
    final quoteCount = r['quotes_count'] ?? r['quote_count'] ?? 0;
    final myQuote = r['my_quote'] as Map<String, dynamic>?;
    final hasQuoted = myQuote != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          GlassWidget(
            borderRadius: 20,
            blurSigma: 16,
            tint: _roleColor.withValues(alpha: 0.06),
            borderColor: _roleColor.withValues(alpha: 0.18),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r['request_number'] != null)
                  Text(r['request_number'],
                      style: TextStyle(
                          color: _roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                if (r['request_number'] != null) const SizedBox(height: 6),
                Text(r['item_name'] ?? 'Barang',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                if (r['category'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(r['category'],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Specs
          _section('Spesifikasi', [
            _row(Icons.inventory_2_outlined, 'Jumlah',
                '${r['quantity']} ${r['unit'] ?? ''}'),
            if (r['specifications'] != null &&
                (r['specifications'] as String).isNotEmpty)
              _row(Icons.description_outlined, 'Spesifikasi',
                  r['specifications']),
            if (r['max_price'] != null)
              _row(Icons.price_check, 'Batas Harga Maks',
                  _fmtCurrency(r['max_price'])),
            if (r['estimated_price'] != null || r['proposed_price'] != null)
              _row(
                  Icons.attach_money,
                  'Harga Perkiraan',
                  _fmtCurrency(
                      r['estimated_price'] ?? r['proposed_price'])),
            _row(Icons.calendar_today_outlined, 'Barang Dibutuhkan',
                _fmtDate(r['needed_by'])),
            _row(Icons.timer_outlined, 'Deadline Penawaran',
                _fmtDate(r['quote_deadline'])),
            if (r['delivery_address'] != null)
              _row(Icons.location_on_outlined, 'Alamat Pengiriman',
                  r['delivery_address']),
          ]),
          const SizedBox(height: 14),

          // Quote count (sealed bid)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.people_outline,
                  color: AppColors.textHint, size: 20),
              const SizedBox(width: 10),
              Text('$quoteCount penawaran sudah masuk',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 14),

          if (r['notes'] != null && (r['notes'] as String).isNotEmpty) ...[
            _section('Catatan Tambahan', [
              _row(Icons.notes_outlined, '', r['notes']),
            ]),
            const SizedBox(height: 14),
          ],

          // Deadline warning
          if (_deadlinePassed)
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.statusDanger.withValues(alpha: 0.06),
              borderColor: AppColors.statusDanger.withValues(alpha: 0.18),
              padding: const EdgeInsets.all(14),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.statusDanger, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Deadline penawaran sudah terlewat. Tidak bisa mengajukan penawaran baru.',
                      style: TextStyle(
                          color: AppColors.statusDanger, fontSize: 13)),
                ),
              ]),
            ),

          // Already quoted
          if (hasQuoted) ...[
            const SizedBox(height: 14),
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.statusInfo.withValues(alpha: 0.06),
              borderColor: AppColors.statusInfo.withValues(alpha: 0.18),
              padding: const EdgeInsets.all(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SupplierQuoteDetailScreen(quoteId: myQuote['id'].toString()),
                  ),
                );
              },
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.statusInfo, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                      'Anda sudah mengajukan penawaran. Ketuk untuk lihat detail.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 18),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          if (!hasQuoted && !_deadlinePassed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Ajukan Penawaran',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final submitted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupplierQuoteFormScreen(
                          procurementRequest: r),
                    ),
                  );
                  if (submitted == true && mounted) _loadDetail();
                },
              ),
            ),
          const SizedBox(height: 40),
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
                  if (label.isNotEmpty)
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
