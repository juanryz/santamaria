import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../kpi/screens/kpi_dashboard_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class TukangAngkatPetiHomeScreen extends StatefulWidget {
  const TukangAngkatPetiHomeScreen({super.key});

  @override
  State<TukangAngkatPetiHomeScreen> createState() =>
      _TukangAngkatPetiHomeScreenState();
}

class _TukangAngkatPetiHomeScreenState
    extends State<TukangAngkatPetiHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  int _tab = 0; // 0 = Tugas, 1 = Riwayat Tagihan

  static const _roleColor = Color(0xFF795548);

  List<dynamic> _assignments = [];
  List<dynamic> _claims = [];
  double _defaultRate = 75000;

  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/vendor/assignments'),
        _api.dio.get('/vendor/wage-claims'),
      ]);
      if (results[0].data['success'] == true) {
        _assignments = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _claims = List<dynamic>.from(results[1].data['data'] ?? []);
      }
      // Try to fetch default rate from system config
      try {
        final rateRes = await _api.dio.get('/system/config/angkat_peti_daily_rate');
        if (rateRes.data['success'] == true) {
          _defaultRate = double.tryParse(
                  rateRes.data['data']?['value']?.toString() ?? '') ??
              75000;
        }
      } catch (_) {
        // Use default rate
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showClaimSheet(Map<String, dynamic> assignment) {
    final order = assignment['order'] as Map<String, dynamic>? ?? {};
    final orderId = (order['id'] ?? assignment['order_id'] ?? '').toString();
    final workersCtrl = TextEditingController(text: '4');
    final daysCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    double rate = _defaultRate;
    double total = 4 * 1 * rate;

    void recalc() {
      final w = int.tryParse(workersCtrl.text) ?? 0;
      final d = int.tryParse(daysCtrl.text) ?? 0;
      total = w * d * rate;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ajukan Tagihan Upah',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(order['order_number'] ?? '-',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 13)),
                  const SizedBox(height: 20),
                  _sheetField('Jumlah Pekerja', workersCtrl,
                      keyboardType: TextInputType.number, onChanged: (_) {
                    recalc();
                    setSheetState(() {});
                  }),
                  const SizedBox(height: 12),
                  _sheetField('Jumlah Hari Kerja', daysCtrl,
                      keyboardType: TextInputType.number, onChanged: (_) {
                    recalc();
                    setSheetState(() {});
                  }),
                  const SizedBox(height: 12),
                  Text('Tarif per hari: ${_currencyFormat.format(rate)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Tagihan',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_currencyFormat.format(total),
                            style: TextStyle(
                                color: _roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sheetField('Catatan (opsional)', notesCtrl, maxLines: 2),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitClaim(
                        ctx,
                        orderId: orderId,
                        workers: int.tryParse(workersCtrl.text) ?? 0,
                        days: int.tryParse(daysCtrl.text) ?? 0,
                        rate: rate,
                        total: total,
                        notes: notesCtrl.text,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _roleColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ajukan Tagihan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl,
      {TextInputType? keyboardType,
      int maxLines = 1,
      ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _submitClaim(
    BuildContext ctx, {
    required String orderId,
    required int workers,
    required int days,
    required double rate,
    required double total,
    required String notes,
  }) async {
    if (workers <= 0 || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pekerja dan hari harus > 0')),
      );
      return;
    }
    try {
      final res = await _api.dio.post('/vendor/wage-claims', data: {
        'order_id': orderId,
        'claimed_amount': total,
        'notes':
            'Pekerja: $workers, Hari: $days, Tarif: ${_currencyFormat.format(rate)}${notes.isNotEmpty ? '. $notes' : ''}',
      });
      if (!mounted) return;
      Navigator.pop(ctx);
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tagihan berhasil diajukan'),
              backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(res.data['message'] ?? 'Gagal mengajukan tagihan')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal mengajukan tagihan'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Koordinator Angkat Peti',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available, color: AppColors.brandPrimary),
            tooltip: 'Cuti & Izin Saya',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyLeavesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.brandPrimary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KpiDashboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const UnifiedLoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: _tab == 0 ? _buildAssignmentsTab() : _buildClaimsTab(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar() => Container(
        color: AppColors.background,
        child: Row(
          children: [
            _tabItem(0, Icons.assignment, 'Tugas'),
            _tabItem(1, Icons.receipt_long, 'Riwayat Tagihan'),
          ],
        ),
      );

  Widget _tabItem(int idx, IconData icon, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _roleColor : AppColors.glassBorder,
                width: active ? 2.5 : 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active ? _roleColor : AppColors.textHint, size: 18),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: active ? _roleColor : AppColors.textHint,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) {
      return const Center(
          child: Text('Belum ada tugas',
              style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (_, i) => _buildAssignmentCard(_assignments[i]),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final order = (a['order'] as Map<String, dynamic>?) ?? {};
    final status = a['status'] as String? ?? 'pending';
    final statusColor = switch (status) {
      'confirmed' => Colors.green,
      'completed' => Colors.blue,
      _ => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(order['order_number'] ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14))),
                GlassStatusBadge(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            if (order['deceased_name'] != null)
              Text('Almarhum: ${order['deceased_name']}',
                  style: const TextStyle(fontSize: 13)),
            if (order['destination_address'] != null)
              Text('Lokasi: ${order['destination_address']}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            if (order['scheduled_at'] != null)
              Text('Jadwal: ${order['scheduled_at']}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showClaimSheet(a),
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('Ajukan Tagihan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimsTab() {
    if (_claims.isEmpty) {
      return const Center(
          child: Text('Belum ada riwayat tagihan',
              style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _claims.length,
      itemBuilder: (_, i) => _buildClaimCard(_claims[i]),
    );
  }

  Widget _buildClaimCard(dynamic c) {
    final order = (c['order'] as Map<String, dynamic>?) ?? {};
    final status = c['status'] as String? ?? 'pending';
    final statusColor = switch (status) {
      'pending' => Colors.orange,
      'approved' => Colors.blue,
      'paid' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
    final statusLabel = switch (status) {
      'pending' => 'Menunggu',
      'approved' => 'Disetujui',
      'paid' => 'Dibayar',
      'rejected' => 'Ditolak',
      _ => status,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(order['order_number'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                GlassStatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            if (order['deceased_name'] != null)
              Text('Almarhum: ${order['deceased_name']}',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
                'Klaim: ${_currencyFormat.format(c['claimed_amount'] ?? 0)}',
                style: const TextStyle(fontSize: 13)),
            if (c['approved_amount'] != null)
              Text(
                  'Disetujui: ${_currencyFormat.format(c['approved_amount'])}',
                  style: const TextStyle(fontSize: 13, color: Colors.blue)),
            if (c['notes'] != null && (c['notes'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Catatan: ${c['notes']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}
