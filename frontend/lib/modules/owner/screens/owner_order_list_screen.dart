import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Owner — list semua order (read-only).
class OwnerOrderListScreen extends StatefulWidget {
  final String title;
  const OwnerOrderListScreen({super.key, this.title = 'Daftar Order'});

  @override
  State<OwnerOrderListScreen> createState() => _OwnerOrderListScreenState();
}

class _OwnerOrderListScreenState extends State<OwnerOrderListScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  static const _roleColor = AppColors.roleOwner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/owner/orders');
      if (res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        if (d is List) {
          _orders = List<dynamic>.from(d);
        } else if (d is Map && d['data'] is List) {
          _orders = List<dynamic>.from(d['data']);
        }
      }
    } catch (e) {
      debugPrint('Owner order list error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: widget.title,
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildItem(_orders[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 72, color: AppColors.textHint),
              SizedBox(height: 16),
              Text(
                'Belum ada order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tarik ke bawah untuk refresh',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(dynamic o) {
    final orderNumber = (o['order_number']?.toString()) ?? '-';
    final deceasedName = (o['deceased_name']?.toString()) ?? '-';
    final status = (o['status']?.toString()) ?? 'pending';
    final createdAt = o['created_at']?.toString();
    final formattedDate = createdAt != null
        ? _formatDate(createdAt)
        : '-';

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _roleColor.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _roleColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _roleColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deceasedName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => AppColors.statusSuccess,
      'cancelled' => AppColors.statusDanger,
      'in_progress' => AppColors.statusInfo,
      'confirmed' || 'approved' => AppColors.brandPrimary,
      _ => AppColors.statusWarning,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu',
      'awaiting_signature' => 'Tunggu TTD',
      'so_review' => 'Review SO',
      'confirmed' => 'Dikonfirmasi',
      'approved' => 'Disetujui',
      'preparing' => 'Disiapkan',
      'ready_to_dispatch' => 'Siap Angkut',
      'driver_assigned' => 'Driver Ditugaskan',
      'delivering_equipment' => 'Antar Barang',
      'equipment_arrived' => 'Barang Tiba',
      'picking_up_body' => 'Jemput Jenazah',
      'body_arrived' => 'Jenazah Tiba',
      'in_ceremony' => 'Prosesi',
      'heading_to_burial' => 'Ke Pemakaman',
      'burial_completed' => 'Pemakaman Selesai',
      'returning_equipment' => 'Kembalikan Barang',
      'completed' => 'Selesai',
      'cancelled' => 'Batal',
      _ => status,
    };
  }
}
