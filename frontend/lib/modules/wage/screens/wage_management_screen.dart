import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

/// Layar Purchasing: kelola tarif, review klaim, bayar upah.
class WageManagementScreen extends StatefulWidget {
  const WageManagementScreen({super.key});

  @override
  State<WageManagementScreen> createState() => _WageManagementScreenState();
}

class _WageManagementScreenState extends State<WageManagementScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> _rates = [];
  List<dynamic> _claims = [];
  List<dynamic> _summary = [];

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/purchasing/wage-rates'),
        _api.dio.get('/purchasing/wage-claims'),
        _api.dio.get('/purchasing/wage-claims/summary'),
      ]);
      _rates = List<dynamic>.from(results[0].data['data'] ?? []);
      _claims = List<dynamic>.from(results[1].data['data'] ?? []);
      _summary = List<dynamic>.from(results[2].data['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Kelola Upah Layanan',
        accentColor: AppColors.rolePurchasing,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brandPrimary,
          indicatorColor: AppColors.brandPrimary,
          tabs: const [
            Tab(text: 'Tarif'),
            Tab(text: 'Klaim'),
            Tab(text: 'Ringkasan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRatesTab(),
                _buildClaimsTab(),
                _buildSummaryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.rolePurchasing,
        onPressed: _showAddRateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Tab 1: Tarif Upah ─────────────────────────────────────────────
  Widget _buildRatesTab() {
    if (_rates.isEmpty) {
      return const Center(child: Text('Belum ada tarif upah. Tekan + untuk menambah.'));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rates.length,
        itemBuilder: (_, i) {
          final r = _rates[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassWidget(
              borderRadius: 12,
              child: ListTile(
                leading: Icon(
                  r['role'] == 'tukang_foto' ? Icons.camera_alt : Icons.people,
                  color: AppColors.rolePurchasing,
                ),
                title: Text(_roleLabel(r['role'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(r['service_package'] ?? 'Semua Paket'),
                trailing: Text(
                  _currencyFormat.format(r['rate_amount'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brandPrimary),
                ),
                onTap: () => _showEditRateDialog(r),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Klaim Masuk ────────────────────────────────────────────
  Widget _buildClaimsTab() {
    if (_claims.isEmpty) {
      return const Center(child: Text('Belum ada klaim upah masuk.'));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        itemBuilder: (_, i) => _buildClaimCard(_claims[i]),
      ),
    );
  }

  Widget _buildClaimCard(dynamic c) {
    final claimant = c['claimant'] ?? {};
    final order = c['order'] ?? {};
    final status = c['status'] ?? 'pending';
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(claimant['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_roleLabel(c['claimant_role'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  GlassStatusBadge(label: _statusLabel(status), color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text('Order: ${order['order_number'] ?? '-'}', style: const TextStyle(fontSize: 13)),
              Text('Klaim: ${_currencyFormat.format(c['claimed_amount'] ?? 0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (c['claim_notes'] != null && (c['claim_notes'] as String).isNotEmpty)
                Text('Catatan: ${c['claim_notes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectClaim(c['id']),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _showApproveDialog(c),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Setujui'),
                      ),
                    ),
                  ],
                ),
              ],
              if (status == 'approved') ...[
                const SizedBox(height: 12),
                Text('Disetujui: ${_currencyFormat.format(c['approved_amount'] ?? 0)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showPayDialog(c),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Bayar Sekarang'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.rolePurchasing),
                  ),
                ),
              ],
              if (status == 'paid' && c['payment'] != null) ...[
                const Divider(height: 16),
                Text('Dibayar: ${_currencyFormat.format(c['payment']['paid_amount'] ?? 0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                Text('Metode: ${(c['payment']['payment_method'] ?? '').toString().toUpperCase()}', style: const TextStyle(fontSize: 12)),
                if (c['payment']['confirmed_by_claimant'] == true)
                  const Text('Dikonfirmasi pekerja', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3: Ringkasan per Pekerja ──────────────────────────────────
  Widget _buildSummaryTab() {
    if (_summary.isEmpty) {
      return const Center(child: Text('Belum ada data upah.'));
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _summary.length,
        itemBuilder: (_, i) {
          final s = _summary[i];
          final claimant = s['claimant'] ?? {};
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassWidget(
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claimant['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_roleLabel(s['claimant_role'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniStat('Pending', s['pending_count'] ?? 0, Colors.orange),
                        _miniStat('Approved', s['approved_count'] ?? 0, Colors.blue),
                        _miniStat('Paid', s['paid_count'] ?? 0, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Belum dibayar:', style: TextStyle(fontSize: 13)),
                        Text(
                          _currencyFormat.format((s['unpaid_total'] ?? 0)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, dynamic count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────

  void _showAddRateDialog() {
    String role = 'tukang_foto';
    final amountCtrl = TextEditingController();
    final packageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Tarif Upah'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'tukang_foto', child: Text('Tukang Foto')),
                  DropdownMenuItem(value: 'tukang_angkat_peti', child: Text('Koordinator Angkat Peti')),
                ],
                onChanged: (v) => role = v ?? role,
              ),
              TextField(controller: packageCtrl, decoration: const InputDecoration(labelText: 'Paket (opsional)', hintText: 'Silver, Gold, Platinum')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Tarif per Order (Rp)'), keyboardType: TextInputType.number),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.dio.post('/purchasing/wage-rates', data: {
                  'role': role,
                  'service_package': packageCtrl.text.isEmpty ? null : packageCtrl.text,
                  'rate_amount': double.tryParse(amountCtrl.text) ?? 0,
                  'notes': notesCtrl.text.isEmpty ? null : notesCtrl.text,
                });
                _loadAll();
              } catch (_) {}
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditRateDialog(dynamic rate) {
    final amountCtrl = TextEditingController(text: '${(rate['rate_amount'] ?? 0).toInt()}');
    final notesCtrl = TextEditingController(text: rate['notes'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Tarif ${_roleLabel(rate['role'] ?? '')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Tarif per Order (Rp)'), keyboardType: TextInputType.number),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.dio.delete('/purchasing/wage-rates/${rate['id']}');
              _loadAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Nonaktifkan'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.dio.put('/purchasing/wage-rates/${rate['id']}', data: {
                'rate_amount': double.tryParse(amountCtrl.text) ?? 0,
                'notes': notesCtrl.text.isEmpty ? null : notesCtrl.text,
              });
              _loadAll();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(dynamic claim) {
    final amountCtrl = TextEditingController(text: '${(claim['claimed_amount'] ?? 0).toInt()}');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Klaim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Jumlah Disetujui (Rp)'), keyboardType: TextInputType.number),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.dio.put('/purchasing/wage-claims/${claim['id']}/approve', data: {
                'approved_amount': double.tryParse(amountCtrl.text) ?? 0,
                'review_notes': notesCtrl.text.isEmpty ? null : notesCtrl.text,
              });
              _loadAll();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectClaim(String claimId) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Klaim'),
        content: TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Alasan penolakan')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.dio.put('/purchasing/wage-claims/$claimId/reject', data: {
        'review_notes': notesCtrl.text,
      });
      _loadAll();
    }
  }

  Future<void> _showPayDialog(dynamic claim) async {
    String method = 'cash';
    final amountCtrl = TextEditingController(text: '${(claim['approved_amount'] ?? claim['claimed_amount'] ?? 0).toInt()}');
    final notesCtrl = TextEditingController();
    XFile? receiptPhoto;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Bayar Upah'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  ],
                  onChanged: (v) => setDialogState(() => method = v ?? method),
                ),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Jumlah Dibayar (Rp)'), keyboardType: TextInputType.number),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
                    if (file != null) setDialogState(() => receiptPhoto = file);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(receiptPhoto != null ? 'Foto diambil' : 'Foto Bukti Pembayaran'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: receiptPhoto != null ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && receiptPhoto != null) {
      final formData = FormData.fromMap({
        'payment_method': method,
        'paid_amount': amountCtrl.text,
        'payment_notes': notesCtrl.text,
        'receipt_photo': await MultipartFile.fromFile(receiptPhoto!.path, filename: 'receipt.jpg'),
      });

      await _api.dio.post('/purchasing/wage-claims/${claim['id']}/pay', data: formData);
      _loadAll();
    }
  }

  String _roleLabel(String role) => switch (role) {
    'tukang_foto' => 'Tukang Foto',
    'tukang_angkat_peti' => 'Koordinator Angkat Peti',
    _ => role,
  };

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Menunggu',
    'approved' => 'Disetujui',
    'paid' => 'Dibayar',
    'rejected' => 'Ditolak',
    _ => status,
  };
}
