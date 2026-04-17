import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// Consumer screen to request order amendments (additional services mid-prosesi)
/// and track existing amendment statuses.
class ConsumerAmendmentScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  const ConsumerAmendmentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<ConsumerAmendmentScreen> createState() => _ConsumerAmendmentScreenState();
}

class _ConsumerAmendmentScreenState extends State<ConsumerAmendmentScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late final TabController _tabCtrl;

  bool _isLoading = true;
  List<dynamic> _amendments = [];

  // New request form
  final List<_AmendmentItem> _newItems = [];
  bool _isSubmitting = false;

  static const _roleColor = AppColors.roleConsumer;

  static const _categories = [
    ('dekorasi', 'Dekorasi'),
    ('konsumsi', 'Konsumsi'),
    ('peralatan', 'Peralatan'),
    ('layanan', 'Layanan'),
    ('lainnya', 'Lainnya'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAmendments();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final item in _newItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAmendments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/consumer/orders/${widget.orderId}/amendments');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _amendments = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _addItem() {
    setState(() {
      _newItems.add(_AmendmentItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _newItems[index].dispose();
      _newItems.removeAt(index);
    });
  }

  Future<void> _submitRequest() async {
    if (_newItems.isEmpty) {
      _snack('Tambahkan minimal 1 item.');
      return;
    }
    for (int i = 0; i < _newItems.length; i++) {
      if (_newItems[i].descCtrl.text.trim().isEmpty) {
        _snack('Deskripsi item ${i + 1} wajib diisi.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final items = _newItems.map((item) => {
        'description': item.descCtrl.text.trim(),
        'qty': int.tryParse(item.qtyCtrl.text.trim()) ?? 1,
        'category': item.category,
        'notes': item.notesCtrl.text.trim(),
      }).toList();

      final res = await _api.dio.post(
        '/consumer/orders/${widget.orderId}/amendments',
        data: {'items': items},
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        _snack('Permintaan tambahan berhasil dikirim.');
        for (final item in _newItems) { item.dispose(); }
        _newItems.clear();
        _tabCtrl.animateTo(1); // Switch to history tab
        _loadAmendments();
      } else {
        _snack(res.data['message'] ?? 'Gagal mengirim permintaan.');
      }
    } catch (e) {
      if (mounted) _snack('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Tambahan Layanan',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: Column(
        children: [
          // Order number badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppColors.backgroundSoft,
            child: Text(widget.orderNumber,
                style: const TextStyle(color: AppColors.textHint, fontSize: 12, letterSpacing: 0.5)),
          ),
          TabBar(
            controller: _tabCtrl,
            labelColor: _roleColor,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: _roleColor,
            tabs: const [
              Tab(text: 'Request Baru'),
              Tab(text: 'Riwayat'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRequestTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Request Tab ───────────────────────────────────────────────────────────

  Widget _buildRequestTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Minta Tambahan Layanan',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                const Text('Tambahkan item yang dibutuhkan. SO akan mereview dan mengirim estimasi biaya.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                const SizedBox(height: 20),
                if (_newItems.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.add_circle_outline, color: AppColors.textHint.withValues(alpha: 0.4), size: 48),
                        const SizedBox(height: 12),
                        const Text('Belum ada item. Ketuk tombol di bawah untuk menambah.',
                            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                else
                  ...List.generate(_newItems.length, (i) => _buildItemCard(i)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Item'),
                    style: OutlinedButton.styleFrom(foregroundColor: _roleColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_newItems.isNotEmpty)
          Container(
            color: AppColors.backgroundSoft,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('KIRIM PERMINTAAN (${_newItems.length} item)'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _newItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Item ${index + 1}', style: const TextStyle(color: _roleColor, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeItem(index),
                child: const Icon(Icons.close, color: AppColors.statusDanger, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Deskripsi Item *',
              hintText: 'Contoh: Karangan Bunga Salib',
              prefixIcon: Icon(Icons.description_outlined, color: AppColors.textHint, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    prefixIcon: Icon(Icons.tag, color: AppColors.textHint, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: item.category,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                  onChanged: (v) => setState(() => item.category = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.notesCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.notes_outlined, color: AppColors.textHint, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_amendments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: AppColors.textHint.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            const Text('Belum ada permintaan tambahan.',
                style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAmendments,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _amendments.length,
        itemBuilder: (_, i) => _buildAmendmentCard(_amendments[i]),
      ),
    );
  }

  Widget _buildAmendmentCard(dynamic amd) {
    final status = amd['status'] as String? ?? '';
    final number = amd['amendment_number'] as String? ?? '';
    final items = amd['items'] as List<dynamic>? ?? [];
    final total = amd['total_estimated_cost'];
    final createdAt = amd['created_at'] as String?;
    final sc = _amendmentStatusColor(status);
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 16, blurSigma: 12,
        tint: AppColors.glassWhite, borderColor: sc.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(number, style: const TextStyle(color: AppColors.textHint, fontSize: 11, letterSpacing: 0.5))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(_amendmentStatusLabel(status),
                      style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '${item['description'] ?? ''} x${item['qty'] ?? 1}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    )),
                  ]),
                )),
            if (total != null && total != 0) ...[
              const SizedBox(height: 8),
              Text('Estimasi: ${currency.format(double.tryParse(total.toString()) ?? 0)}',
                  style: const TextStyle(color: _roleColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.tryParse(createdAt) ?? DateTime.now()),
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
            // Approve/Reject buttons if status is so_reviewed
            if (status == 'so_reviewed') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondAmendment(amd['id'], 'reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusDanger),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondAmendment(amd['id'], 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusSuccess, foregroundColor: Colors.white),
                    child: const Text('Setuju'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _respondAmendment(String amdId, String action) async {
    try {
      await _api.dio.put('/consumer/orders/${widget.orderId}/amendments/$amdId/$action');
      if (mounted) {
        _snack(action == 'approve' ? 'Tambahan disetujui.' : 'Tambahan ditolak.');
        _loadAmendments();
      }
    } catch (_) {
      if (mounted) _snack('Gagal memproses. Coba lagi.');
    }
  }

  Color _amendmentStatusColor(String status) => switch (status) {
    'requested' => AppColors.statusWarning,
    'so_reviewed' => AppColors.statusInfo,
    'family_approved' => AppColors.statusSuccess,
    'preparing' => AppColors.roleSO,
    'dispatched' => AppColors.roleDriver,
    'delivered' => AppColors.roleGudang,
    'executing' => AppColors.roleDekor,
    'completed' => AppColors.statusSuccess,
    'rejected' || 'cancelled' => AppColors.statusDanger,
    _ => AppColors.textHint,
  };

  String _amendmentStatusLabel(String status) => switch (status) {
    'requested' => 'Menunggu SO',
    'so_reviewed' => 'Estimasi Tersedia',
    'family_approved' => 'Disetujui',
    'preparing' => 'Disiapkan',
    'dispatched' => 'Dikirim',
    'delivered' => 'Tiba',
    'executing' => 'Dikerjakan',
    'completed' => 'Selesai',
    'rejected' => 'Ditolak',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}

class _AmendmentItem {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final notesCtrl = TextEditingController();
  String category = 'lainnya';

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    notesCtrl.dispose();
  }
}
