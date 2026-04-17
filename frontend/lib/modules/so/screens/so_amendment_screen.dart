import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// SO screen to review, price, and manage order amendments.
class SOAmendmentScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  const SOAmendmentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<SOAmendmentScreen> createState() => _SOAmendmentScreenState();
}

class _SOAmendmentScreenState extends State<SOAmendmentScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late final TabController _tabCtrl;

  bool _isLoading = true;
  List<dynamic> _amendments = [];

  // Create new amendment form
  final List<_SOAmendmentItem> _newItems = [];
  String _urgency = 'normal';
  String _requestedVia = 'so_on_behalf';
  bool _isSubmitting = false;

  static const _roleColor = AppColors.roleSO;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _categories = [
    ('dekorasi', 'Dekorasi'),
    ('konsumsi', 'Konsumsi'),
    ('peralatan', 'Peralatan'),
    ('layanan', 'Layanan'),
    ('lainnya', 'Lainnya'),
  ];

  static const _itemTypes = [
    ('add_item', 'Tambah Item'),
    ('upgrade_item', 'Upgrade'),
    ('swap_item', 'Tukar'),
    ('add_quantity', 'Tambah Qty'),
    ('add_vendor', 'Tambah Vendor'),
    ('extend_duration', 'Perpanjang Durasi'),
    ('custom', 'Lainnya'),
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
    for (final item in _newItems) { item.dispose(); }
    super.dispose();
  }

  Future<void> _loadAmendments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/so/orders/${widget.orderId}/amendments');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _amendments = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _addItem() => setState(() => _newItems.add(_SOAmendmentItem()));

  void _removeItem(int i) {
    setState(() { _newItems[i].dispose(); _newItems.removeAt(i); });
  }

  Future<void> _submitAmendment() async {
    if (_newItems.isEmpty) { _snack('Tambahkan minimal 1 item.'); return; }
    for (int i = 0; i < _newItems.length; i++) {
      if (_newItems[i].descCtrl.text.trim().isEmpty) {
        _snack('Deskripsi item ${i + 1} wajib diisi.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final items = _newItems.map((item) => {
        'item_type': item.itemType,
        'description': item.descCtrl.text.trim(),
        'qty': int.tryParse(item.qtyCtrl.text.trim()) ?? 1,
        'category': item.category,
        'unit_price': double.tryParse(item.priceCtrl.text.trim()) ?? 0,
        'notes': item.notesCtrl.text.trim(),
      }).toList();

      final res = await _api.dio.post(
        '/so/orders/${widget.orderId}/amendments',
        data: {
          'requested_via': _requestedVia,
          'urgency': _urgency,
          'items': items,
        },
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        _snack('Amendment berhasil dibuat.');
        for (final item in _newItems) { item.dispose(); }
        _newItems.clear();
        _urgency = 'normal';
        _tabCtrl.animateTo(1);
        _loadAmendments();
      } else {
        _snack(res.data['message'] ?? 'Gagal membuat amendment.');
      }
    } catch (e) {
      if (mounted) _snack('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendEstimate(String amdId) async {
    try {
      await _api.dio.put('/so/orders/${widget.orderId}/amendments/$amdId/review');
      if (mounted) { _snack('Estimasi dikirim ke keluarga.'); _loadAmendments(); }
    } catch (_) { if (mounted) _snack('Gagal mengirim estimasi.'); }
  }

  Future<void> _captureSignature(String amdId) async {
    final sigKey = GlobalKey<_SignaturePadState>();
    final nameCtrl = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanda Tangan Keluarga',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama PJ Keluarga *'),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, height: 150,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _SignaturePad(key: sigKey),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => sigKey.currentState?.clear(), child: const Text('Bersihkan')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || (sigKey.currentState?.isEmpty ?? true)) return;
                    final nav = Navigator.of(ctx);
                    final image = await sigKey.currentState!.toImage();
                    if (image == null) return;
                    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
                    if (bytes == null) return;
                    nav.pop({
                      'name': nameCtrl.text.trim(),
                      'signature': base64Encode(bytes.buffer.asUint8List()),
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    if (result == null || !mounted) return;

    try {
      await _api.dio.put(
        '/so/orders/${widget.orderId}/amendments/$amdId/capture-signature',
        data: result,
      );
      if (mounted) { _snack('Tanda tangan berhasil disimpan.'); _loadAmendments(); }
    } catch (_) { if (mounted) _snack('Gagal menyimpan tanda tangan.'); }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Amendment',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: Column(
        children: [
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
              Tab(text: 'Buat Amendment'),
              Tab(text: 'Riwayat'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCreateTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Tab ────────────────────────────────────────────────────────────

  Widget _buildCreateTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Buat Amendment',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                // Urgency & source
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _urgency,
                        decoration: const InputDecoration(labelText: 'Urgency'),
                        items: const [
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (v) => setState(() => _urgency = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _requestedVia,
                        decoration: const InputDecoration(labelText: 'Sumber'),
                        items: const [
                          DropdownMenuItem(value: 'so_on_behalf', child: Text('Atas nama keluarga')),
                          DropdownMenuItem(value: 'so_input', child: Text('Inisiatif SO')),
                        ],
                        onChanged: (v) => setState(() => _requestedVia = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Items
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
                onPressed: _isSubmitting ? null : _submitAmendment,
                style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('BUAT AMENDMENT'),
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
          DropdownButtonFormField<String>(
            initialValue: item.itemType,
            decoration: const InputDecoration(labelText: 'Jenis'),
            items: _itemTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
            onChanged: (v) => setState(() => item.itemType = v!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Deskripsi *', prefixIcon: Icon(Icons.description_outlined, color: AppColors.textHint, size: 20)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(
              controller: item.qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Qty'),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: item.category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
              onChanged: (v) => setState(() => item.category = v!),
            )),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Harga per unit (Rp)', prefixIcon: Icon(Icons.attach_money, color: AppColors.textHint, size: 20)),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.notesCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history, color: AppColors.textHint.withValues(alpha: 0.4), size: 48),
          const SizedBox(height: 12),
          const Text('Belum ada amendment.', style: TextStyle(color: AppColors.textHint)),
        ]),
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
    final urgency = amd['urgency'] as String? ?? 'normal';
    final total = amd['total_estimated_cost'];
    final sc = _statusColor(status);
    final uc = urgency == 'critical' ? AppColors.statusDanger : urgency == 'urgent' ? AppColors.statusWarning : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 16, blurSigma: 12,
        tint: AppColors.glassWhite, borderColor: sc.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(number, style: const TextStyle(color: AppColors.textHint, fontSize: 11))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: uc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(urgency.toUpperCase(), style: TextStyle(color: uc, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(_statusLabel(status), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
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
                    if (item['unit_price'] != null && item['unit_price'] != 0)
                      Text(_currency.format(double.tryParse(item['unit_price'].toString()) ?? 0),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                )),
            if (total != null && total != 0) ...[
              const SizedBox(height: 6),
              Text('Total: ${_currency.format(double.tryParse(total.toString()) ?? 0)}',
                  style: const TextStyle(color: _roleColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
            // Action buttons based on status
            if (status == 'requested') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendEstimate(amd['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white),
                  child: const Text('Kirim Estimasi ke Keluarga'),
                ),
              ),
            ],
            if (status == 'so_reviewed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _captureSignature(amd['id']),
                  icon: const Icon(Icons.draw, size: 18),
                  label: const Text('Capture Tanda Tangan Keluarga'),
                  style: OutlinedButton.styleFrom(foregroundColor: _roleColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
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

  String _statusLabel(String s) => switch (s) {
    'requested' => 'Menunggu Review',
    'so_reviewed' => 'Estimasi Dikirim',
    'family_approved' => 'Disetujui',
    'preparing' => 'Disiapkan',
    'dispatched' => 'Dikirim',
    'delivered' => 'Tiba',
    'executing' => 'Dikerjakan',
    'completed' => 'Selesai',
    'rejected' => 'Ditolak',
    'cancelled' => 'Dibatalkan',
    _ => s,
  };
}

class _SOAmendmentItem {
  String itemType = 'add_item';
  String category = 'lainnya';
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  void dispose() { descCtrl.dispose(); qtyCtrl.dispose(); priceCtrl.dispose(); notesCtrl.dispose(); }
}

// ══════════════════════════════════════════════════════════════════════════════
// SignaturePad widget (for capture-signature bottom sheet)
// ══════════════════════════════════════════════════════════════════════════════

class _SignaturePad extends StatefulWidget {
  const _SignaturePad({super.key});
  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  bool get isEmpty => _strokes.isEmpty && _currentStroke == null;

  void clear() => setState(() { _strokes.clear(); _currentStroke = null; });

  Future<ui.Image?> toImage() async {
    if (isEmpty) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    final paint = Paint()..color = Colors.black..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final stroke in _strokes) { _drawStroke(canvas, stroke, paint); }
    return recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) { canvas.drawPoints(ui.PointMode.points, points, paint); return; }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1]; final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => setState(() => _currentStroke = [d.localPosition]),
      onPanUpdate: (d) => setState(() => _currentStroke?.add(d.localPosition)),
      onPanEnd: (_) {
        if (_currentStroke != null && _currentStroke!.isNotEmpty) {
          setState(() { _strokes.add(List.of(_currentStroke!)); _currentStroke = null; });
        }
      },
      child: CustomPaint(painter: _SigPainter(strokes: _strokes, currentStroke: _currentStroke), size: Size.infinite),
    );
  }
}

class _SigPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  _SigPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final stroke in strokes) { _draw(canvas, stroke, paint); }
    if (currentStroke != null) _draw(canvas, currentStroke!, paint);
  }

  void _draw(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.isEmpty) return;
    if (pts.length == 1) { canvas.drawPoints(ui.PointMode.points, pts, paint); return; }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1]; final p1 = pts[i];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SigPainter old) => true;
}
