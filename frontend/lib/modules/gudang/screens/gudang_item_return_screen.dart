import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class GudangItemReturnScreen extends StatefulWidget {
  const GudangItemReturnScreen({super.key});

  @override
  State<GudangItemReturnScreen> createState() => _GudangItemReturnScreenState();
}

class _GudangItemReturnScreenState extends State<GudangItemReturnScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/returns/pending');
      if (res.data['success'] == true) {
        _orders = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Pengembalian Barang',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.statusSuccess),
                          SizedBox(height: 12),
                          Text(
                            'Semua barang sudah dikembalikan',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) => _OrderReturnCard(
                      order: _orders[i],
                      onCompleted: _loadData,
                    ),
                  ),
      ),
    );
  }
}

class _OrderReturnCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onCompleted;

  const _OrderReturnCard({required this.order, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final orderNumber = order['order_number'] as String? ?? '-';
    final almarhum = order['almarhum_name'] as String? ??
        order['deceased_name'] as String? ??
        '-';
    final itemCount = (order['returnable_count'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: AppColors.roleGudang.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(16),
        onTap: () async {
          final orderId = order['id']?.toString() ?? '';
          if (orderId.isEmpty) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ReturnFormScreen(
                orderId: orderId,
                orderNumber: orderNumber,
              ),
            ),
          );
          onCompleted();
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.roleGudang.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.swap_horiz,
                  color: AppColors.roleGudang, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14)),
                  Text(almarhum,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$itemCount item',
                style: const TextStyle(
                    color: AppColors.statusWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Return Form per Order ───────────────────────────────────────────────────

class _ReturnFormScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const _ReturnFormScreen({
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<_ReturnFormScreen> createState() => _ReturnFormScreenState();
}

class _ReturnFormScreenState extends State<_ReturnFormScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _items = [];

  static const _roleColor = AppColors.roleGudang;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final res =
          await _api.dio.get('/gudang/orders/${widget.orderId}/returnable-items');
      if (res.data['success'] == true) {
        final raw = List<dynamic>.from(res.data['data'] ?? []);
        _items = raw.map((e) {
          final m = Map<String, dynamic>.from(e);
          m['_return_qty'] = 0.0;
          m['_damaged_qty'] = 0.0;
          m['_notes'] = '';
          return m;
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  double get _totalBillingReduction {
    double total = 0;
    for (final item in _items) {
      if (item['item_nature'] == 'pakai_kembali') {
        final retQty = _toDouble(item['_return_qty']);
        final unitPrice = _toDouble(item['unit_price']);
        total += retQty * unitPrice;
      }
    }
    return total;
  }

  bool get _hasReturns {
    return _items.any((e) =>
        _toDouble(e['_return_qty']) > 0 || _toDouble(e['_damaged_qty']) > 0);
  }

  Future<void> _submit() async {
    if (!_hasReturns) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSoft,
        title: const Text('Konfirmasi Pengembalian',
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proses pengembalian untuk ${widget.orderNumber}?',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (_totalBillingReduction > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 16, color: AppColors.statusSuccess),
                    const SizedBox(width: 8),
                    Text(
                      'Potongan tagihan: ${_currency.format(_totalBillingReduction)}',
                      style: const TextStyle(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _roleColor),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final payload = _items
          .where((e) =>
              _toDouble(e['_return_qty']) > 0 ||
              _toDouble(e['_damaged_qty']) > 0)
          .map((e) => {
                'stock_item_id': e['stock_item_id'],
                'item_nature': e['item_nature'],
                'qty_sent': _toDouble(e['qty_sent']),
                'qty_returned': _toDouble(e['_return_qty']),
                'qty_damaged': _toDouble(e['_damaged_qty']),
                if ((e['_notes'] as String).isNotEmpty)
                  'notes': e['_notes'],
              })
          .toList();

      await _api.dio.post(
        '/gudang/orders/${widget.orderId}/returns',
        data: {'items': payload},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengembalian berhasil diproses'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses pengembalian')),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  String _natureName(String? nature) {
    switch (nature) {
      case 'sewa':
        return 'Sewa';
      case 'pakai_kembali':
        return 'Pakai Bisa Kembali';
      case 'pakai_habis':
        return 'Pakai Habis';
      default:
        return nature ?? '-';
    }
  }

  Color _natureColor(String? nature) {
    switch (nature) {
      case 'sewa':
        return AppColors.statusInfo;
      case 'pakai_kembali':
        return AppColors.statusWarning;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.orderNumber,
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Group by nature
                      ..._buildSection(
                        'Peralatan Sewa',
                        Icons.build_outlined,
                        AppColors.statusInfo,
                        _items
                            .where((e) => e['item_nature'] == 'sewa')
                            .toList(),
                      ),
                      ..._buildSection(
                        'Barang Bisa Kembali',
                        Icons.swap_vert,
                        AppColors.statusWarning,
                        _items
                            .where(
                                (e) => e['item_nature'] == 'pakai_kembali')
                            .toList(),
                      ),
                      // Info-only section for pakai_habis
                      if (_items
                          .any((e) => e['item_nature'] == 'pakai_habis'))
                        _buildReadonlySection(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                // Bottom bar with billing impact + submit
                _buildBottomBar(),
              ],
            ),
    );
  }

  List<Widget> _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
      ...items.map((item) => _buildItemCard(item)),
    ];
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item['item_name'] as String? ?? '-';
    final nature = item['item_nature'] as String? ?? '-';
    final qtySent = _toDouble(item['qty_sent']);
    final alreadyReturned = _toDouble(item['qty_already_returned']);
    final remaining = qtySent - alreadyReturned;
    final unit = item['unit'] as String? ?? 'pcs';
    final unitPrice = _toDouble(item['unit_price']);
    final returnQty = _toDouble(item['_return_qty']);
    final isReturnableConsumable = nature == 'pakai_kembali';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: _natureColor(nature).withValues(alpha: 0.15),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 13)),
                ),
                GlassStatusBadge(
                  label: _natureName(nature),
                  color: _natureColor(nature),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kirim: ${qtySent.toStringAsFixed(0)} $unit  |  Sisa belum kembali: ${remaining.toStringAsFixed(0)} $unit',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberInput(
                    label: 'Kembali',
                    max: remaining,
                    value: _toDouble(item['_return_qty']),
                    onChanged: (v) => setState(() => item['_return_qty'] = v),
                  ),
                ),
                const SizedBox(width: 10),
                if (nature == 'sewa')
                  Expanded(
                    child: _numberInput(
                      label: 'Rusak/Hilang',
                      max: remaining,
                      value: _toDouble(item['_damaged_qty']),
                      onChanged: (v) =>
                          setState(() => item['_damaged_qty'] = v),
                      color: AppColors.statusDanger,
                    ),
                  ),
              ],
            ),
            if (isReturnableConsumable && returnQty > 0 && unitPrice > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Potongan: ${returnQty.toStringAsFixed(0)} x ${_currency.format(unitPrice)} = ${_currency.format(returnQty * unitPrice)}',
                  style: const TextStyle(
                      color: AppColors.statusSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numberInput({
    required String label,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
    Color? color,
  }) {
    final c = color ?? _roleColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            _circleBtn(
              icon: Icons.remove,
              color: c,
              onTap: value > 0
                  ? () => onChanged((value - 1).clamp(0, max))
                  : null,
            ),
            Expanded(
              child: Text(
                value.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: c),
              ),
            ),
            _circleBtn(
              icon: Icons.add,
              color: c,
              onTap: value < max
                  ? () => onChanged((value + 1).clamp(0, max))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? color.withValues(alpha: 0.12)
              : AppColors.textHint.withValues(alpha: 0.08),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : AppColors.textHint.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? color : AppColors.textHint.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildReadonlySection() {
    final habisItems =
        _items.where((e) => e['item_nature'] == 'pakai_habis').toList();
    if (habisItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
              SizedBox(width: 8),
              Text('Barang Habis Pakai (info)',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHint)),
            ],
          ),
        ),
        ...habisItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassWidget(
                borderRadius: 12,
                blurSigma: 8,
                tint: AppColors.glassWhite,
                borderColor: AppColors.glassBorder,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['item_name'] ?? '-',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${_toDouble(item['qty_sent']).toStringAsFixed(0)} ${item['unit'] ?? ''}  -  terpakai',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        border: Border(
          top: BorderSide(color: AppColors.textHint.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_totalBillingReduction > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long,
                      size: 16, color: AppColors.statusSuccess),
                  const SizedBox(width: 6),
                  Text(
                    'Potongan tagihan: ${_currency.format(_totalBillingReduction)}',
                    style: const TextStyle(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_hasReturns && !_isSubmitting) ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: _roleColor,
                disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle, size: 20),
              label: Text(
                _isSubmitting ? 'Memproses...' : 'Proses Pengembalian',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
