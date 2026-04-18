import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.40 — Stock Opname Detail: count fisik per item, catat selisih, reconcile.
class StockOpnameDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const StockOpnameDetailScreen({super.key, required this.session});

  @override
  State<StockOpnameDetailScreen> createState() =>
      _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _session = {};
  List<dynamic> _items = [];
  String _filter = 'all'; // all, counted, uncounted, variance

  @override
  void initState() {
    super.initState();
    _session = Map<String, dynamic>.from(widget.session);
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Reload session dari /stock-opname/sessions/start (idempotent — akan return existing + items)
      final res = await _api.dio.post('/stock-opname/sessions/start');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        setState(() {
          _session = data;
          _items = List<dynamic>.from(data['items'] ?? []);
        });
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat item.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat item opname.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _countItem(
      Map<String, dynamic> item, num actualQty, String? notes) async {
    final sid = _session['id'];
    final iid = item['id'];
    if (sid == null || iid == null) return;

    try {
      final res = await _api.dio.put(
        '/stock-opname/sessions/$sid/items/$iid/count',
        data: {
          'actual_quantity': actualQty,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        // Update item lokal tanpa reload semua
        final idx = _items.indexWhere((x) => x['id'] == iid);
        if (idx >= 0) {
          setState(() =>
              _items[idx] = Map<String, dynamic>.from(res.data['data']));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Hitungan tersimpan'),
              backgroundColor: AppColors.statusSuccess,
              duration: Duration(milliseconds: 800)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal menyimpan'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyimpan hitungan'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Future<void> _openCountDialog(Map<String, dynamic> item) async {
    final stockItem = item['stock_item'] as Map<String, dynamic>?;
    final current = num.tryParse('${item['actual_quantity']}') ?? 0;
    final ctrl = TextEditingController(text: current == 0 ? '' : '$current');
    final noteCtrl = TextEditingController(text: '${item['notes'] ?? ''}');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(stockItem?['item_name'] ?? 'Hitung Stok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok Sistem: ${item['system_quantity']} ${stockItem?['unit'] ?? ''}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah Fisik (Aktual)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final n = num.tryParse(ctrl.text);
              if (n == null || n < 0) return;
              Navigator.pop(ctx, {'qty': n, 'notes': noteCtrl.text});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _countItem(item, result['qty'] as num, result['notes'] as String?);
    }
  }

  Future<void> _reconcile() async {
    final varianceItems = _items
        .where((i) =>
            (num.tryParse('${i['variance']}') ?? 0) != 0 &&
            i['reconciled_at'] == null)
        .length;

    final ok = await ConfirmDialog.show(
      context,
      title: 'Rekonsiliasi Opname?',
      message: varianceItems == 0
          ? 'Tidak ada selisih. Sesi akan ditutup.'
          : '$varianceItems item ada selisih — stok sistem akan disamakan dengan fisik, dan transaksi adjustment dibuat otomatis.',
      confirmLabel: 'Rekonsiliasi',
      confirmColor: AppColors.statusSuccess,
    );
    if (!ok) return;

    try {
      final res = await _api.dio
          .post('/stock-opname/sessions/${_session['id']}/reconcile');
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Opname selesai & stok direkonsiliasi.'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal rekonsiliasi'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal rekonsiliasi'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  List<dynamic> get _filteredItems {
    return switch (_filter) {
      'counted' => _items
          .where((i) =>
              (num.tryParse('${i['actual_quantity']}') ?? 0) !=
              (num.tryParse('${i['system_quantity']}') ?? 0) ||
              i['notes'] != null)
          .toList(),
      'uncounted' => _items
          .where((i) =>
              (num.tryParse('${i['actual_quantity']}') ?? 0) ==
              (num.tryParse('${i['system_quantity']}') ?? 0) &&
              i['notes'] == null)
          .toList(),
      'variance' => _items
          .where((i) => (num.tryParse('${i['variance']}') ?? 0) != 0)
          .toList(),
      _ => _items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = (_session['status'] ?? 'open').toString();
    final isCompleted = status == 'completed' || status == 'reviewed';
    final year = _session['period_year'];
    final sem = _session['period_semester'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Opname $sem $year',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      floatingActionButton: isCompleted
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.statusSuccess,
              onPressed: _reconcile,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Rekonsiliasi',
                  style: TextStyle(color: Colors.white)),
            ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _buildSummary(isCompleted),
                      _buildFilterChips(),
                      Expanded(
                        child: _filteredItems.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.inventory_outlined,
                                title: 'Tidak Ada Item',
                                subtitle:
                                    'Ganti filter atau mulai sesi opname baru.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                itemCount: _filteredItems.length,
                                itemBuilder: (c, i) => _itemCard(
                                    _filteredItems[i] as Map<String, dynamic>,
                                    isCompleted),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummary(bool isCompleted) {
    final totalItems = _items.length;
    final variance = _items
        .where((i) => (num.tryParse('${i['variance']}') ?? 0) != 0)
        .length;
    final counted = _items
        .where((i) =>
            (num.tryParse('${i['actual_quantity']}') ?? 0) !=
            (num.tryParse('${i['system_quantity']}') ?? 0) ||
            i['notes'] != null)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassWidget(
        padding: const EdgeInsets.all(14),
        borderColor: AppColors.roleGudang.withOpacity(0.2),
        child: Row(
          children: [
            _stat('Total', '$totalItems', AppColors.textPrimary),
            _divider(),
            _stat('Dihitung', '$counted/$totalItems',
                AppColors.brandPrimary),
            _divider(),
            _stat('Selisih', '$variance',
                variance > 0 ? AppColors.statusWarning : AppColors.statusSuccess),
            if (isCompleted) ...[
              _divider(),
              const GlassStatusBadge(
                  label: 'Selesai', color: AppColors.statusSuccess),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.textHint.withOpacity(0.25),
      );

  Widget _buildFilterChips() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          spacing: 8,
          children: [
            _chip('Semua', 'all'),
            _chip('Terhitung', 'counted'),
            _chip('Belum Dihitung', 'uncounted'),
            _chip('Ada Selisih', 'variance'),
          ],
        ),
      );

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
      labelStyle: TextStyle(
          color:
              selected ? AppColors.brandPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
    );
  }

  Widget _itemCard(Map<String, dynamic> item, bool isCompleted) {
    final stockItem = item['stock_item'] as Map<String, dynamic>?;
    final name = stockItem?['item_name'] ?? '-';
    final unit = stockItem?['unit'] ?? '';
    final code = stockItem?['item_code'] ?? '';
    final system = num.tryParse('${item['system_quantity']}') ?? 0;
    final actual = num.tryParse('${item['actual_quantity']}') ?? 0;
    final variance = num.tryParse('${item['variance']}') ?? 0;
    final reconciled = item['reconciled_at'] != null;

    final varianceColor = variance == 0
        ? AppColors.statusSuccess
        : (variance > 0 ? AppColors.statusInfo : AppColors.statusDanger);

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: variance != 0
          ? varianceColor.withOpacity(0.3)
          : AppColors.glassBorder,
      onTap: isCompleted ? null : () => _openCountDialog(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              if (code.toString().isNotEmpty)
                Text(code.toString(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _qtyBlock('Sistem', '$system $unit', AppColors.textSecondary),
              const SizedBox(width: 16),
              _qtyBlock('Aktual', '$actual $unit', AppColors.brandPrimary),
              const Spacer(),
              if (variance != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: varianceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '${variance > 0 ? '+' : ''}${variance.toString()}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: varianceColor,
                          fontSize: 13)),
                ),
              if (reconciled) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified,
                    size: 18, color: AppColors.statusSuccess),
              ],
            ],
          ),
          if ((item['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item['notes'],
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _qtyBlock(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 14)),
        ],
      );

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
                  onPressed: _loadItems, child: const Text('Coba Lagi'))),
        ],
      );
}
