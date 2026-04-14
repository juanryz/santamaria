import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import 'equipment_checklist_screen.dart';
import 'consumable_daily_screen.dart';

/// Screen khusus Gudang untuk melihat order aktif + checklist stok per order.
class GudangOrdersScreen extends StatefulWidget {
  const GudangOrdersScreen({super.key});

  @override
  State<GudangOrdersScreen> createState() => _GudangOrdersScreenState();
}

class _GudangOrdersScreenState extends State<GudangOrdersScreen> {
  final _api = ApiClient();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch checklist orders — orders that are 'confirmed' need Gudang attention
      final res = await _api.dio.get('/gudang/orders');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _orders = List<dynamic>.from(res.data['data'] ?? []));
      } else if (res.data['data'] != null) {
        // Some endpoints return data array directly without 'success' key
        final data = res.data['data'];
        if (data is List) {
          setState(() => _orders = data);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat data order.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.statusDanger,
        'confirmed' => AppColors.statusWarning,
        'approved' => AppColors.statusSuccess,
        'in_progress' => AppColors.statusInfo,
        'completed' => AppColors.statusSuccess,
        'cancelled' => AppColors.textHint,
        _ => AppColors.textHint,
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => 'ORDER BARU',
        'confirmed' => 'Perlu Cek Stok',
        'approved' => 'Stok Siap',
        'in_progress' => 'Sedang Berjalan',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => s.toUpperCase(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Order Aktif',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _orders.length,
                          itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                        ),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusDanger),
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Tidak ada order aktif.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            SizedBox(height: 6),
            Text('Order baru akan muncul di sini saat SO konfirmasi.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final sc = _statusColor(status);
    final pkg = order['package'] as Map<String, dynamic>?;
    final scheduledAt =
        order['scheduled_at'] != null ? DateTime.tryParse(order['scheduled_at']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: status == 'confirmed'
            ? _roleColor.withValues(alpha: 0.3)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                if (status == 'confirmed')
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.statusWarning, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['order_number'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: sc,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // PIC Info
            _infoRow(Icons.person_outline, 'PIC',
                order['pic_name'] ?? '-'),
            const SizedBox(height: 4),
            // Package Info
            if (pkg != null) ...[
              _infoRow(Icons.inventory_2_outlined, 'Paket', pkg['name'] ?? '-'),
              const SizedBox(height: 4),
            ],
            // Jadwal
            if (scheduledAt != null)
              _infoRow(
                Icons.calendar_today_outlined,
                'Jadwal',
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(scheduledAt.toLocal()),
              ),
            // Needs restock badge
            if (order['needs_restock'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusDanger.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded,
                        color: AppColors.statusDanger, size: 14),
                    SizedBox(width: 6),
                    Text('Stok kurang — Buat PO!',
                        style: TextStyle(
                            color: AppColors.statusDanger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action button → checklist
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openChecklist(
                    context, order['id'] as String, order['order_number'] ?? ''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'confirmed'
                      ? _roleColor
                      : AppColors.textHint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: Text(status == 'confirmed'
                    ? 'Cek & Siapkan Stok'
                    : (status == 'pending' ? 'Belum Ada Checklist' : 'Lihat Checklist')),
              ),
            ),
            // v1.14 — Equipment & Consumable shortcuts
            if (status != 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EquipmentChecklistScreen(orderId: order['id']),
                      )),
                      icon: const Icon(Icons.build_outlined, size: 16),
                      label: const Text('Peralatan', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: _roleColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ConsumableDailyScreen(orderId: order['id']),
                      )),
                      icon: const Icon(Icons.inventory_outlined, size: 16),
                      label: const Text('Konsumabel', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: _roleColor),
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

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      );

  Future<void> _openChecklist(
      BuildContext context, String orderId, String orderNumber) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _GudangChecklistScreen(orderId: orderId, orderNumber: orderNumber),
      ),
    );
    _load(); // refresh after returning
  }
}

// ─── Checklist Screen ──────────────────────────────────────────────────────

class _GudangChecklistScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const _GudangChecklistScreen(
      {required this.orderId, required this.orderNumber});

  @override
  State<_GudangChecklistScreen> createState() => _GudangChecklistScreenState();
}

class _GudangChecklistScreenState extends State<_GudangChecklistScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isConfirming = false;
  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res =
          await _api.dio.get('/gudang/orders/${widget.orderId}/checklist');
      if (mounted) setState(() => _data = res.data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat checklist.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(String itemId, bool current) async {
    try {
      await _api.dio.put(
        '/gudang/orders/${widget.orderId}/checklist/$itemId',
        data: {'is_checked': !current},
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengupdate item.')),
        );
      }
    }
  }

  Future<void> _confirmReady() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Stok Siap?'),
        content: const Text(
            'Semua item sudah dicek. Konfirmasi stok siap akan memicu penugasan driver.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSuccess),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isConfirming = true);
    try {
      final res = await _api.dio
          .put('/gudang/orders/${widget.orderId}/stock-ready');
      if (mounted) {
        final msg =
            res.data['message'] ?? 'Stok siap! Driver mendapat notifikasi.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengonfirmasi stok siap.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _data == null
        ? <dynamic>[]
        : List<dynamic>.from(_data!['checklist'] ?? []);
    final order = _data?['order'] as Map<String, dynamic>?;
    final checked = _data?['checked'] as int? ?? 0;
    final total = _data?['total'] as int? ?? 0;
    final allChecked = total > 0 && checked >= total;
    final orderStatus = order?['status'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Checklist — ${widget.orderNumber}',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress Checklist',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          Text('$checked / $total',
                              style: TextStyle(
                                  color: _roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total > 0 ? checked / total : 0,
                          backgroundColor:
                              _roleColor.withValues(alpha: 0.15),
                          color: _roleColor,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Checklist items
                Expanded(
                  child: checklist.isEmpty
                      ? const Center(
                          child: Text('Tidak ada item checklist.',
                              style: TextStyle(
                                  color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: checklist.length,
                          itemBuilder: (_, i) {
                            final item =
                                Map<String, dynamic>.from(checklist[i]);
                            final isChecked =
                                item['is_checked'] as bool? ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: GlassWidget(
                                borderRadius: 14,
                                blurSigma: 10,
                                tint: isChecked
                                    ? AppColors.statusSuccess
                                        .withValues(alpha: 0.06)
                                    : AppColors.glassWhite,
                                borderColor: isChecked
                                    ? AppColors.statusSuccess
                                        .withValues(alpha: 0.3)
                                    : AppColors.glassBorder,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                onTap: orderStatus == 'confirmed'
                                    ? () => _toggleItem(
                                        item['id'] as String, isChecked)
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      color: isChecked
                                          ? AppColors.statusSuccess
                                          : AppColors.textHint,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['item_name'] ?? '-',
                                            style: TextStyle(
                                              color: isChecked
                                                  ? AppColors.textSecondary
                                                  : AppColors.textPrimary,
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 14,
                                              decoration: isChecked
                                                  ? TextDecoration
                                                      .lineThrough
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            '${item['quantity'] ?? 1} ${item['unit'] ?? 'pcs'}',
                                            style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isChecked)
                                      const Icon(
                                        Icons.check,
                                        color: AppColors.statusSuccess,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Confirm Button
                if (orderStatus == 'confirmed')
                  Container(
                    color: AppColors.backgroundSoft,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: allChecked && !_isConfirming
                            ? _confirmReady
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isConfirming
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline,
                                size: 20),
                        label: Text(_isConfirming
                            ? 'Mengonfirmasi...'
                            : 'Konfirmasi Stok Siap'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
