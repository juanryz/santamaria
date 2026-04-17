import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/order_timeline_widget.dart';
import 'consumer_gallery_screen.dart';
import 'consumer_payment_screen.dart';
import 'consumer_acceptance_screen.dart';
import 'consumer_amendment_screen.dart';
import '../../tukang_foto/screens/gallery_link_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _api = ApiClient();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _order;
  List<dynamic> _photos = [];
  Map<String, dynamic>? _quota;
  List<dynamic> _addonsList = [];
  bool _isAddingAddon = false;

  static const _roleColor = AppColors.roleConsumer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/consumer/orders/${widget.orderId}'),
        _api.dio.get('/consumer/storage-quota'),
        _api.dio.get('/addons'),
      ]);
      if (!mounted) return;
      if (results[0].data['success'] == true) {
        final d = results[0].data['data'];
        _order = Map<String, dynamic>.from(d);
        _photos = List<dynamic>.from(d['photos'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _quota = Map<String, dynamic>.from(results[1].data['data'] ?? {});
      }
      if (results[2].data['success'] == true) {
        _addonsList = List<dynamic>.from(results[2].data['data'] ?? []);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1920,
    );
    if (xfile == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(xfile.path, filename: xfile.name),
      });
      final res = await _api.dio.post(
        '/consumer/orders/${widget.orderId}/photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diunggah.')),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto.')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.roleConsumer,
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.roleConsumer,
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Hapus Foto?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Foto akan dihapus permanen.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.dio.delete(
        '/consumer/orders/${widget.orderId}/photos/$photoId',
      );
      if (!mounted) return;
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus foto.')));
      }
    }
  }

  Color _statusColor(String s) => switch (s) {
    'pending' => AppColors.statusWarning,
    'so_review' || 'admin_review' => const Color(0xFFFF9800),
    'approved' => AppColors.roleConsumer,
    'in_progress' => AppColors.statusSuccess,
    'completed' => AppColors.roleSO,
    'cancelled' => AppColors.statusDanger,
    _ => AppColors.textHint,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Menunggu SO',
    'so_review' => 'Diproses SO',
    'admin_review' => 'Menunggu Persetujuan',
    'approved' => 'Disetujui',
    'in_progress' => 'Dalam Perjalanan',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _order?['order_number'] ?? 'Status Layanan',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(
              child: Text(
                'Order tidak ditemukan.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(),
                    const SizedBox(height: 16),
                    _buildProgressBar(),
                    // v1.17 — Acceptance / T&C signature banner
                    if (_order!['status'] == 'confirmed' && _order!['acceptance_signed_at'] == null) ...[
                      const SizedBox(height: 12),
                      GlassWidget(
                        borderRadius: 14,
                        blurSigma: 10,
                        tint: Colors.orange.withValues(alpha: 0.08),
                        borderColor: Colors.orange.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_document, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('Tanda tangani Surat Penerimaan Layanan',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ConsumerAcceptanceScreen(orderId: widget.orderId),
                                  ));
                                  if (result == true) _load();
                                },
                                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                                child: const Text('Tanda Tangan Sekarang'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_order!['status'] == 'completed') ...[
                      _buildGalleryBanner(),
                      const SizedBox(height: 8),
                      // Google Drive gallery links dari Tukang Foto
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => GalleryLinkScreen(orderId: widget.orderId),
                          )),
                          icon: const Icon(Icons.add_to_drive, size: 18),
                          label: const Text('Lihat Album Foto (Google Drive)'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4285F4)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // v1.14 — Payment button
                      if (_order!['payment_status'] != 'paid' && _order!['payment_status'] != 'verified')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ConsumerPaymentScreen(
                                    orderId: widget.orderId,
                                    orderNumber: _order!['order_number'] ?? '',
                                    totalPrice: double.tryParse(_order!['final_price']?.toString() ?? '0') ?? 0,
                                  ),
                                ));
                                if (result == true) _load();
                              },
                              icon: const Icon(Icons.payment),
                              label: const Text('Lakukan Pembayaran'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _roleColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                    _buildTimeline(),
                    const SizedBox(height: 20),
                    _buildInfo(),
                    const SizedBox(height: 20),
                    if (_order!['driver'] != null) ...[
                      _buildDriverCard(),
                      const SizedBox(height: 20),
                    ],
                    _buildAddonSection(),
                    const SizedBox(height: 20),
                    // Amendment button — visible when order is confirmed or in_progress
                    if (_order!['status'] == 'confirmed' ||
                        _order!['status'] == 'in_progress' ||
                        _order!['status'] == 'preparing' ||
                        _order!['status'] == 'ready_to_dispatch' ||
                        _order!['status'] == 'driver_assigned' ||
                        _order!['status'] == 'delivering_equipment' ||
                        _order!['status'] == 'equipment_arrived' ||
                        _order!['status'] == 'picking_up_body' ||
                        _order!['status'] == 'body_arrived' ||
                        _order!['status'] == 'in_ceremony') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsumerAmendmentScreen(
                                orderId: widget.orderId,
                                orderNumber: _order!['order_number'] ?? '',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                          label: const Text('Tambahan Layanan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _roleColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildPhotoSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddonSection() {
    final List<dynamic> activeAddons = _order!['order_add_ons'] ?? [];
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LAYANAN TAMBAHAN (ADD-ON)',
              style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            if (_order!['status'] == 'confirmed' ||
                _order!['status'] == 'in_progress')
              TextButton.icon(
                onPressed: _showAddAddonModal,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: _roleColor,
                ),
                label: const Text(
                  'Tambah',
                  style: TextStyle(color: _roleColor, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (activeAddons.isEmpty)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'Belum ada layanan tambahan.',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            ),
          )
        else
          ...activeAddons.map((oa) {
            final addon = oa['add_on_service'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassWidget(
                borderRadius: 16,
                blurSigma: 16,
                tint: AppColors.glassWhite,
                borderColor: AppColors.glassBorder,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_task,
                      color: AppColors.statusSuccess,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addon['name'] ?? '-',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${oa['quantity']}x @ ${currency.format(double.tryParse(oa['price_at_time'].toString()) ?? 0)}',
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(
                        (double.tryParse(oa['price_at_time'].toString()) ?? 0) *
                            (oa['quantity'] ?? 1),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddAddonModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tambah Layanan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _addonsList.length,
                    itemBuilder: (context, index) {
                      final addon = _addonsList[index];
                      final currency = NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          addon['name'],
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          currency.format(
                            double.tryParse(addon['price'].toString()) ?? 0,
                          ),
                          style: const TextStyle(color: AppColors.textHint),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: _roleColor),
                          onPressed: _isAddingAddon
                              ? null
                              : () => _submitAddon(addon['id'], setModalState),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitAddon(String addonId, StateSetter setModalState) async {
    setModalState(() => _isAddingAddon = true);
    try {
      final res = await _api.dio.post(
        '/consumer/orders/${widget.orderId}/addons',
        data: {'add_on_service_id': addonId, 'quantity': 1},
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        Navigator.pop(context);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan tambahan berhasil ditambahkan.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Gagal menambahkan layanan.')),
        );
      }
    } finally {
      if (mounted) setModalState(() => _isAddingAddon = false);
    }
  }

  // ── Consumer Progress Bar ──────────────────────────────────────────────────

  static const _consumerSteps = [
    {'label': 'Order Diterima', 'icon': Icons.receipt_long_outlined, 'statuses': ['pending', 'awaiting_signature', 'so_review']},
    {'label': 'Dikonfirmasi', 'icon': Icons.check_circle_outline, 'statuses': ['confirmed']},
    {'label': 'Perlengkapan Disiapkan', 'icon': Icons.inventory_2_outlined, 'statuses': ['preparing', 'ready_to_dispatch']},
    {'label': 'Dalam Perjalanan', 'icon': Icons.local_shipping_outlined, 'statuses': ['driver_assigned', 'delivering_equipment']},
    {'label': 'Tiba di Lokasi', 'icon': Icons.location_on_outlined, 'statuses': ['equipment_arrived', 'picking_up_body', 'body_arrived']},
    {'label': 'Prosesi Berlangsung', 'icon': Icons.church_outlined, 'statuses': ['in_ceremony']},
    {'label': 'Menuju Pemakaman', 'icon': Icons.directions_car_outlined, 'statuses': ['heading_to_burial', 'burial_completed', 'returning_equipment']},
    {'label': 'Selesai', 'icon': Icons.task_alt_outlined, 'statuses': ['completed']},
  ];

  int _currentStepIndex() {
    final status = _order?['status'] as String? ?? '';
    if (status == 'cancelled') return -1;
    for (int i = 0; i < _consumerSteps.length; i++) {
      if ((_consumerSteps[i]['statuses'] as List<String>).contains(status)) return i;
    }
    return 0;
  }

  Widget _buildProgressBar() {
    final current = _currentStepIndex();
    final isCancelled = (_order?['status'] as String? ?? '') == 'cancelled';
    final total = _consumerSteps.length;
    final progress = isCancelled ? 0.0 : ((current + 1) / total).clamp(0.0, 1.0);

    final logs = List<Map<String, dynamic>>.from(
      (_order?['status_logs'] as List?)?.map((l) => Map<String, dynamic>.from(l)) ?? [],
    );

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESS LAYANAN',
            style: TextStyle(
              color: _roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(
                isCancelled ? AppColors.statusDanger : AppColors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCancelled
                ? 'Dibatalkan'
                : '${current + 1} dari $total langkah',
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
          const SizedBox(height: 20),
          // Step timeline
          ...List.generate(_consumerSteps.length, (i) {
            final step = _consumerSteps[i];
            final label = step['label'] as String;
            final icon = step['icon'] as IconData;
            final stepStatuses = step['statuses'] as List<String>;
            final isCompleted = !isCancelled && current >= 0 && i < current;
            final isCurrent = !isCancelled && i == current;
            final isFuture = isCancelled || current < 0 || i > current;
            final isLast = i == _consumerSteps.length - 1;

            // Find timestamp from logs
            String? timestamp;
            for (final s in stepStatuses) {
              final match = logs.where((l) => l['to_status'] == s).toList();
              if (match.isNotEmpty) {
                timestamp = match.last['created_at'] as String?;
                break;
              }
            }

            return _buildStepItem(
              label: label,
              icon: icon,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isFuture: isFuture,
              isLast: isLast,
              timestamp: timestamp,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String label,
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
    required bool isFuture,
    required bool isLast,
    String? timestamp,
  }) {
    final dotColor = isCompleted
        ? AppColors.statusSuccess
        : isCurrent
            ? _roleColor
            : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 18 : 14,
                  height: isCurrent ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? dotColor : (isCurrent ? dotColor.withValues(alpha: 0.15) : Colors.grey.shade100),
                    border: Border.all(color: dotColor, width: isCurrent ? 3 : 1.5),
                    boxShadow: isCurrent
                        ? [BoxShadow(color: _roleColor.withValues(alpha: 0.25), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.statusSuccess.withValues(alpha: 0.4) : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Icon + label + timestamp
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isFuture ? Colors.grey.shade300 : (isCurrent ? _roleColor : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isCurrent ? 14 : 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isFuture ? Colors.grey.shade400 : AppColors.textPrimary,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _fmtTs(timestamp),
                            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          )
                        else if (isFuture)
                          const Text(
                            'Menunggu...',
                            style: TextStyle(fontSize: 10, color: AppColors.textHint),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTs(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }

  Widget _buildStatusBanner() {
    final status = _order!['status'] as String? ?? '';
    final color = _statusColor(status);
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: color.withValues(alpha: 0.07),
      borderColor: color.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(_statusIcon(status), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _order!['deceased_name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _order!['order_number'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryBanner() {
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsumerGalleryScreen(orderId: widget.orderId),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.roleConsumer.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.photo_library,
              color: AppColors.roleConsumer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lihat Galeri & Berita Duka',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Foto, video pasca acara, dan berita duka',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = _order!['status'] as String? ?? '';
    final logs = List<Map<String, dynamic>>.from(
      (_order!['status_logs'] as List?)?.map((l) => Map<String, dynamic>.from(l)) ?? [],
    );

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALUR PROSES',
            style: TextStyle(
              color: _roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // v1.17 — DB-driven timeline (labels from ConfigService, NOT hardcoded)
          OrderTimelineWidget(
            currentStatus: status,
            statusLogs: logs,
            showConsumerView: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final order = _order!;
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id');
    String? fmtDate(String? s) {
      if (s == null) return null;
      final dt = DateTime.tryParse(s);
      return dt == null ? null : fmt.format(dt.toLocal());
    }

    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAIL LAYANAN',
            style: TextStyle(
              color: _roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (order['scheduled_at'] != null)
            _infoRow(
              Icons.calendar_today_outlined,
              'Jadwal',
              fmtDate(order['scheduled_at']) ?? '-',
            ),
          if (order['pickup_address'] != null)
            _infoRow(
              Icons.location_on_outlined,
              'Penjemputan',
              order['pickup_address'],
            ),
          if (order['destination_address'] != null)
            _infoRow(
              Icons.flag_outlined,
              'Tujuan',
              order['destination_address'],
            ),
          if (order['package'] != null)
            _infoRow(
              Icons.inventory_2_outlined,
              'Paket',
              order['package']['name'] ?? '-',
            ),
          if (order['final_price'] != null)
            _infoRow(
              Icons.payments_outlined,
              'Harga Paket',
              currency.format(
                double.tryParse(order['final_price'].toString()) ?? 0,
              ),
            ),
          if (order['total_price'] != null &&
              order['total_price'] != order['final_price'])
            _infoRow(
              Icons.calculate_outlined,
              'Total yang Harus Dibayar',
              currency.format(
                double.tryParse(order['total_price'].toString()) ?? 0,
              ),
              isBold: true,
            ),
          _infoRow(
            Icons.receipt_long_outlined,
            'Status Pembayaran',
            _paymentLabel(order['payment_status'] ?? 'unpaid'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    final driver = _order!['driver'] as Map<String, dynamic>;
    final isInProgress = _order!['status'] == 'in_progress';
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.statusSuccess.withValues(alpha: 0.05),
      borderColor: AppColors.statusSuccess.withValues(alpha: 0.20),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.statusSuccess.withValues(alpha: 0.15),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.statusSuccess,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Ditugaskan',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  driver['name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (driver['phone'] != null)
                  Text(
                    driver['phone'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isInProgress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'AKTIF',
                style: TextStyle(
                  color: AppColors.statusSuccess,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final usedMb =
        ((_quota?['used_bytes'] as num?)?.toDouble() ?? 0) / (1024 * 1024);
    final quotaMb =
        ((_quota?['quota_bytes'] as num?)?.toDouble() ?? 1024) / (1024 * 1024);
    final pct = usedMb / quotaMb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Foto Kenangan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _pickAndUpload,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _roleColor,
                    ),
                    tooltip: 'Tambah Foto',
                  ),
          ],
        ),

        // Quota bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: AppColors.glassBorder,
            valueColor: AlwaysStoppedAnimation(
              pct > 0.85 ? AppColors.statusDanger : _roleColor,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${usedMb.toStringAsFixed(0)} MB / ${(quotaMb / 1024).toStringAsFixed(0)} GB digunakan',
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
        const SizedBox(height: 16),

        if (_photos.isEmpty)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(28),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.textHint,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada foto.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ketuk ikon + di atas untuk menambah.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final url = photo['url'] as String? ?? '';
              return GestureDetector(
                onTap: url.isEmpty ? null : () => _viewPhoto(url),
                onLongPress: () => _deletePhoto(photo['id'].toString()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url.isEmpty
                      ? Container(
                          color: AppColors.backgroundSoft,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textHint,
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: AppColors.backgroundSoft,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Tahan foto untuk menghapus',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ),
      ],
    );
  }

  void _viewPhoto(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full-screen interactive image
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (ctx, err, st) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isBold ? _roleColor : AppColors.textHint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isBold ? _roleColor : AppColors.textHint,
                  fontSize: 11,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  IconData _statusIcon(String s) => switch (s) {
    'pending' => Icons.hourglass_empty_rounded,
    'so_review' || 'admin_review' => Icons.pending_actions_rounded,
    'approved' => Icons.thumb_up_alt_rounded,
    'in_progress' => Icons.directions_car_rounded,
    'completed' => Icons.check_circle_rounded,
    'cancelled' => Icons.cancel_rounded,
    _ => Icons.info_outline_rounded,
  };

  String _paymentLabel(String s) => switch (s) {
    'unpaid' => 'Belum Dibayar',
    'partial' => 'Sebagian Terbayar',
    'paid' => 'Lunas',
    _ => s,
  };
}
