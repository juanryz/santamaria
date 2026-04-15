import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class ConsumerDeliveryScreen extends StatefulWidget {
  final String orderId;

  const ConsumerDeliveryScreen({super.key, required this.orderId});

  @override
  State<ConsumerDeliveryScreen> createState() => _ConsumerDeliveryScreenState();
}

class _ConsumerDeliveryScreenState extends State<ConsumerDeliveryScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _deliveries = [];

  static const _roleColor = AppColors.roleConsumer;

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
      final res = await _api.dio
          .get('/consumer/orders/${widget.orderId}/deliveries');
      if (res.data['success'] == true) {
        setState(
            () => _deliveries = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelivery(String deliveryId) async {
    try {
      final res = await _api.dio
          .post('/consumer/deliveries/$deliveryId/confirm');
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penerimaan barang dikonfirmasi!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(res.data['message'] ?? 'Gagal konfirmasi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal konfirmasi. Periksa koneksi Anda.')),
        );
      }
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  List<dynamic> get _pendingDeliveries =>
      _deliveries.where((d) => d['status'] == 'received_by_jaga').toList();

  List<dynamic> get _confirmedDeliveries =>
      _deliveries.where((d) => d['status'] == 'confirmed_by_family').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Penerimaan Barang',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _deliveries.isEmpty
                      ? _buildEmpty()
                      : _buildContent(),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusDanger, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'Belum ada pengiriman barang',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildContent() {
    final pending = _pendingDeliveries;
    final confirmed = _confirmedDeliveries;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader(
              'Menunggu Konfirmasi Anda', Colors.orange, Icons.pending_actions),
          const SizedBox(height: 8),
          ...pending.map((d) => _buildDeliveryCard(d, isPending: true)),
          const SizedBox(height: 16),
        ],
        if (confirmed.isNotEmpty) ...[
          _sectionHeader(
              'Sudah Dikonfirmasi', AppColors.statusSuccess, Icons.check_circle_outline),
          const SizedBox(height: 8),
          ...confirmed.map((d) => _buildDeliveryCard(d, isPending: false)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      );

  Widget _buildDeliveryCard(Map<String, dynamic> delivery,
      {required bool isPending}) {
    final items = List<dynamic>.from(delivery['items'] ?? []);
    final statusColor =
        isPending ? Colors.orange : AppColors.statusSuccess;
    final statusLabel =
        isPending ? 'Menunggu Konfirmasi' : 'Dikonfirmasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 18,
        blurSigma: 14,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          delivery['received_by'] ??
                              delivery['received_by_name'] ??
                              '-',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(delivery['received_at'] ??
                      delivery['delivered_at']),
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Barang:',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.textHint)),
                      Text(
                        '${item['item_name'] ?? '-'} x ${item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )),
            if (isPending) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      _confirmDelivery(delivery['id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'KONFIRMASI TERIMA DARI TUKANG JAGA',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
