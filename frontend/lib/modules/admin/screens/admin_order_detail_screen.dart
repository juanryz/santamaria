import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'musician_sessions_screen.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/admin/orders/${widget.orderId}');
      if (res.data['success'] == true) {
        setState(() => _order = res.data['data']);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String s) => switch (s) {
        'admin_review' => AppColors.statusWarning,
        'approved' => AppColors.roleConsumer,
        'in_progress' => AppColors.statusSuccess,
        'completed' => AppColors.roleSO,
        'cancelled' => AppColors.statusDanger,
        _ => AppColors.textHint,
      };

  String _statusLabel(String s) => switch (s) {
        'pending' => 'Menunggu',
        'so_review' => 'Review SO',
        'approved' => 'Disetujui',
        'in_progress' => 'Sedang Berjalan',
        'completed' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        _ => s,
      };

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _order?['order_number'] ?? 'Detail Order',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.music_note, color: AppColors.brandAccent),
              tooltip: 'Sesi Musisi',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MusicianSessionsScreen(
                    orderId: widget.orderId,
                    orderNumber: _order!['order_number'] ?? '-',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(
                  child: Text('Order tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 20),
                        _buildSection('Data Almarhum', [
                          _row('Nama', _order!['deceased_name']),
                          _row('Tanggal Meninggal',
                              _formatDate(_order!['deceased_dod'])),
                          _row('Agama',
                              (_order!['deceased_religion'] as String?)
                                  ?.toUpperCase()),
                          _row('Alamat Penjemputan',
                              _order!['pickup_address']),
                          _row('Tujuan', _order!['destination_address']),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('Penanggung Jawab (PIC)', [
                          _row('Nama',
                              (_order!['pic'] as Map?)?['name']),
                          _row('Nomor HP', _order!['pic_phone']),
                          _row('Hubungan', _order!['pic_relation']),
                          _row('Alamat', _order!['pic_address']),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('Paket & Harga', [
                          _row('Paket',
                              (_order!['package'] as Map?)?['name'] ?? '-'),
                          _row(
                            'Harga Paket',
                            _order!['final_price'] != null
                                ? 'Rp ${NumberFormat('#,###').format(double.tryParse(_order!['final_price'].toString()) ?? 0)}'
                                : '-',
                          ),
                          if ((_order!['order_add_ons'] as List?)?.isNotEmpty == true) ...[
                            _row('Add-Ons', 
                              (_order!['order_add_ons'] as List).map((oa) => "${oa['add_on_service']['name']} (x${oa['quantity']})").join(', ')
                            ),
                          ],
                          _row(
                            'Total Biaya',
                            _order!['total_price'] != null
                                ? 'Rp ${NumberFormat('#,###').format(double.tryParse(_order!['total_price'].toString()) ?? 0)}'
                                : '-',
                          ),
                          _row('Jadwal',
                              _formatDate(_order!['scheduled_at'])),
                          _row('Driver',
                              (_order!['driver'] as Map?)?['name'] ?? '-'),
                          _row('Kendaraan',
                              (_order!['vehicle'] as Map?)?['model'] ?? '-'),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('Pembayaran', [
                          _row(
                              'Status',
                              (_order!['payment_status'] ?? 'unpaid')
                                  .toString()
                                  .toUpperCase()),
                          _row(
                            'Jumlah',
                            _order!['payment_amount'] != null
                                ? 'Rp ${NumberFormat('#,###').format(double.tryParse(_order!['payment_amount'].toString()) ?? 0)}'
                                : '-',
                          ),
                          _row('Catatan Admin', _order!['admin_notes']),
                        ]),
                        if ((_order!['status_logs'] as List?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 16),
                          _buildTimeline(),
                        ],
                        const SizedBox(height: 24),
                        _buildActions(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _order!['status'] as String? ?? '';
    final color = _statusColor(status);
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 16,
      tint: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            _statusLabel(status),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Spacer(),
          Text(
            _formatDate(_order!['created_at']),
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final logs = List<dynamic>.from(_order!['status_logs'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Status',
            style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        const SizedBox(height: 12),
        ...logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _roleColor,
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 28,
                          color: AppColors.glassBorder),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log['from_status']} → ${log['to_status']}',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        if (log['notes'] != null)
                          Text(log['notes'],
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        Text(
                          _formatDate(log['created_at']),
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActions() {
    final status = _order!['status'] as String? ?? '';

    if (status == 'approved' || status == 'in_progress') {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _showPaymentDialog,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('UPDATE PEMBAYARAN'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _confirmClose,
            icon: const Icon(Icons.lock_outline),
            label: const Text('TUTUP ORDER'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showPaymentDialog() async {
    final statusCtrl =
        ValueNotifier<String>(_order!['payment_status'] ?? 'unpaid');
    final amtCtrl = TextEditingController(
        text: _order!['payment_amount']?.toString() ?? '');
    final notesCtrl =
        TextEditingController(text: _order!['payment_notes'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Pembayaran',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: statusCtrl,
                builder: (_, val, _) => DropdownButtonFormField<String>(
                  initialValue: val,
                  decoration:
                      const InputDecoration(labelText: 'Status Pembayaran'),
                  items: const [
                    DropdownMenuItem(
                        value: 'unpaid', child: Text('Belum Dibayar')),
                    DropdownMenuItem(
                        value: 'partial', child: Text('Sebagian')),
                    DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                  ],
                  onChanged: (v) => statusCtrl.value = v!,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Jumlah Pembayaran (Rp)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _api.dio.put(
                        '/admin/orders/${widget.orderId}/payment',
                        data: {
                          'payment_status': statusCtrl.value,
                          'payment_amount':
                              double.tryParse(amtCtrl.text) ?? 0,
                          'payment_notes': notesCtrl.text,
                        });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Gagal update pembayaran.')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor),
                child: const Text('SIMPAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClose() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tutup Order'),
        content: const Text(
            'Yakin ingin menutup order ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusDanger),
              child: const Text('Tutup')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _api.dio.put('/admin/orders/${widget.orderId}/close');
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menutup order.')));
      }
    }
  }
}
