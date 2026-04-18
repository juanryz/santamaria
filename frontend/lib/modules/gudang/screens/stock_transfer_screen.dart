import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'stock_transfer_request_form.dart';

/// v1.40 — Inter-location Stock Transfer.
/// Flow: Gudang request → Super Admin (kantor) approve →
///       driver mark transferred → Gudang receive → stok sync.
/// Termasuk untuk barang titipan supplier kacang (source_supplier_id).
class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _transfers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/stock-transfers');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _transfers =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat transfer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Map<String, dynamic> transfer, String action) async {
    final id = transfer['id'];
    final endpoint = switch (action) {
      'approve' => '/stock-transfers/$id/approve',
      'transfer' => '/stock-transfers/$id/mark-transferred',
      'receive' => '/stock-transfers/$id/receive',
      'cancel' => '/stock-transfers/$id/cancel',
      _ => null,
    };
    if (endpoint == null) return;

    try {
      final res = await _api.dio.put(endpoint);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'OK'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal memproses transfer'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Transfer Stok',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const StockTransferRequestForm()),
          );
          if (result == true) _load();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Request Transfer',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _transfers.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

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
                  onPressed: _load, child: const Text('Coba Lagi'))),
        ],
      );

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.compare_arrows,
        title: 'Belum Ada Transfer',
        subtitle: 'Transfer stok antar lokasi akan muncul di sini.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transfers.length,
        itemBuilder: (c, i) => _transferCard(_transfers[i] as Map<String, dynamic>),
      );

  Widget _transferCard(Map<String, dynamic> t) {
    final status = (t['status'] ?? 'requested').toString();
    final from = (t['from_owner_role'] ?? '').toString();
    final to = (t['to_owner_role'] ?? '').toString();
    final qty = num.tryParse('${t['quantity']}') ?? 0;
    final item = t['stock_item'] as Map<String, dynamic>?;
    final itemName = item?['item_name'] ?? '-';
    final unit = item?['unit'] ?? '';
    final requestedAt = DateTime.tryParse(t['requested_at'] ?? '');
    final supplier = t['source_supplier'] as Map<String, dynamic>?;
    final isConsignment = supplier != null;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.roleGudang.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(itemName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _locationChip(_label(from)),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.textHint),
              _locationChip(_label(to)),
              const Spacer(),
              Text('${qty.toStringAsFixed(0)} $unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          if (isConsignment) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_shipping,
                    size: 14, color: AppColors.brandAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                      'Barang titipan supplier: ${supplier?['name'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.brandAccent)),
                ),
              ],
            ),
          ],
          if (requestedAt != null) ...[
            const SizedBox(height: 4),
            Text(
                'Diminta: ${DateFormat('d MMM yyyy HH:mm', 'id_ID').format(requestedAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
          if (_actionButtons(status).isNotEmpty) ...[
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              children: _actionButtons(status).map((a) {
                return OutlinedButton(
                  onPressed: () => _action(t, a.action),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: a.color,
                    side: BorderSide(color: a.color.withOpacity(0.5)),
                  ),
                  child: Text(a.label),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.brandSecondary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary)),
      );

  String _label(String role) => switch (role) {
        'gudang' => 'Gudang',
        'super_admin' => 'Kantor',
        'dekor' => 'Lafiore',
        _ => role,
      };

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'completed' => ('Selesai', AppColors.statusSuccess),
      'in_transit' => ('Dalam Perjalanan', AppColors.statusInfo),
      'approved' => ('Disetujui', AppColors.brandPrimary),
      'requested' => ('Menunggu', AppColors.statusWarning),
      'cancelled' => ('Dibatalkan', AppColors.statusDanger),
      _ => (status, AppColors.textHint),
    };
    return GlassStatusBadge(label: label, color: color);
  }

  List<_Action> _actionButtons(String status) {
    return switch (status) {
      'requested' => [
          const _Action('Approve', 'approve', AppColors.statusSuccess),
          const _Action('Batal', 'cancel', AppColors.statusDanger),
        ],
      'approved' => [
          const _Action('Mulai Kirim', 'transfer', AppColors.statusInfo),
        ],
      'in_transit' => [
          const _Action('Terima', 'receive', AppColors.statusSuccess),
        ],
      _ => <_Action>[],
    };
  }
}

class _Action {
  final String label;
  final String action;
  final Color color;
  const _Action(this.label, this.action, this.color);
}
