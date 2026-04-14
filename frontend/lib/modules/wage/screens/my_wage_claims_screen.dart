import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import 'package:intl/intl.dart';

class MyWageClaimsScreen extends StatefulWidget {
  const MyWageClaimsScreen({super.key});

  @override
  State<MyWageClaimsScreen> createState() => _MyWageClaimsScreenState();
}

class _MyWageClaimsScreenState extends State<MyWageClaimsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  List<dynamic> _claims = [];
  Map<String, dynamic> _summary = {};

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/vendor/wage-claims'),
        _api.dio.get('/vendor/wage-claims/summary'),
      ]);
      if (results[0].data['success'] == true) {
        _claims = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _summary = Map<String, dynamic>.from(results[1].data['data'] ?? {});
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> claimForOrder(String orderId) async {
    try {
      final res = await _api.dio.post('/vendor/wage-claims', data: {'order_id': orderId});
      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message'] ?? 'Klaim berhasil diajukan'), backgroundColor: Colors.green),
          );
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengajukan klaim'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmReceived(String claimId) async {
    try {
      await _api.dio.put('/vendor/wage-claims/$claimId/confirm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penerimaan upah dikonfirmasi'), backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Klaim Upah Saya', accentColor: AppColors.brandPrimary),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      _summaryCard('Menunggu', _summary['pending_amount'] ?? 0, Colors.orange),
                      const SizedBox(width: 8),
                      _summaryCard('Disetujui', _summary['approved_amount'] ?? 0, Colors.blue),
                      const SizedBox(width: 8),
                      _summaryCard('Dibayar', _summary['paid_amount'] ?? 0, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlassWidget(
                    borderRadius: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Belum Dibayar', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            _currencyFormat.format(_summary['total_unpaid'] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Riwayat Klaim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_claims.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada klaim upah')))
                  else
                    ..._claims.map((c) => _buildClaimCard(c)),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard(String label, num amount, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_currencyFormat.format(amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(dynamic c) {
    final order = c['order'] ?? {};
    final status = c['status'] ?? 'pending';
    final payment = c['payment'];
    final statusColor = switch (status) {
      'pending' => Colors.orange,
      'approved' => Colors.blue,
      'paid' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order['order_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                  GlassStatusBadge(label: _statusLabel(status), color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              if (order['deceased_name'] != null) Text('Almarhum: ${order['deceased_name']}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text('Klaim: ${_currencyFormat.format(c['claimed_amount'] ?? 0)}', style: const TextStyle(fontSize: 13)),
              if (c['approved_amount'] != null)
                Text('Disetujui: ${_currencyFormat.format(c['approved_amount'])}', style: const TextStyle(fontSize: 13, color: Colors.blue)),
              if (c['review_notes'] != null && (c['review_notes'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Catatan: ${c['review_notes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              if (payment != null) ...[
                const Divider(height: 16),
                Text('Dibayar: ${_currencyFormat.format(payment['paid_amount'] ?? 0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
                Text('Metode: ${(payment['payment_method'] ?? '').toString().toUpperCase()}', style: const TextStyle(fontSize: 12)),
                if (payment['confirmed_by_claimant'] != true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _confirmReceived(c['id']),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Konfirmasi Sudah Terima'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Menunggu',
    'approved' => 'Disetujui',
    'paid' => 'Dibayar',
    'rejected' => 'Ditolak',
    _ => status,
  };
}
