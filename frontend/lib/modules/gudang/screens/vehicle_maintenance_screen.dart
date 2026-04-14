import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/dynamic_status_badge.dart';

class VehicleMaintenanceScreen extends StatefulWidget {
  const VehicleMaintenanceScreen({super.key});

  @override
  State<VehicleMaintenanceScreen> createState() => _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState extends State<VehicleMaintenanceScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  late TabController _tabCtrl;
  List<dynamic> _maintenance = [];
  List<dynamic> _fuelLogs = [];
  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/gudang/maintenance-requests'),
        _api.dio.get('/gudang/fuel-logs'),
      ]);
      if (results[0].data['success'] == true) {
        _maintenance = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _fuelLogs = List<dynamic>.from(results[1].data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _ackMaintenance(String id) async {
    try {
      await _api.dio.put('/gudang/maintenance-requests/$id/acknowledge');
      _loadData();
    } catch (_) {}
  }

  Future<void> _completeMaintenance(String id) async {
    final notesCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Perbaikan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan penyelesaian *')),
            const SizedBox(height: 8),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Biaya (Rp)', prefixText: 'Rp ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Selesai')),
        ],
      ),
    );
    if (result == true && notesCtrl.text.isNotEmpty) {
      try {
        await _api.dio.put('/gudang/maintenance-requests/$id/complete', data: {
          'resolution_notes': notesCtrl.text,
          'cost': double.tryParse(costCtrl.text),
        });
        _loadData();
      } catch (_) {}
    }
  }

  Future<void> _validateFuel(String id) async {
    try {
      await _api.dio.put('/gudang/fuel-logs/$id/validate');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fuel log divalidasi')));
    } catch (_) {}
  }

  Future<void> _rejectFuel(String id) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Fuel Log'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Alasan penolakan')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Tolak')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await _api.dio.put('/gudang/fuel-logs/$id/reject', data: {'reason': result});
        _loadData();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Kendaraan & Maintenance',
        accentColor: _roleColor,
        bottom: TabBar(controller: _tabCtrl, labelColor: _roleColor, tabs: const [
          Tab(text: 'Maintenance'),
          Tab(text: 'Validasi BBM'),
        ]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildMaintenanceTab(),
              _buildFuelTab(),
            ]),
    );
  }

  Widget _buildMaintenanceTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _maintenance.isEmpty
          ? const Center(child: Text('Tidak ada laporan maintenance'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _maintenance.length,
              itemBuilder: (_, i) {
                final m = _maintenance[i];
                final status = m['status'] ?? '';
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
                              Icon(_priorityIcon(m['priority'] ?? ''), color: _priorityColor(m['priority'] ?? ''), size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(m['vehicle']?['model'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DynamicStatusBadge(enumGroup: 'procurement_status', value: status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Kategori: ${m['category'] ?? '-'} | Pelapor: ${m['reporter']?['name'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(m['description'] ?? '', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 12),
                          if (status == 'reported')
                            FilledButton(onPressed: () => _ackMaintenance(m['id']), style: FilledButton.styleFrom(backgroundColor: _roleColor, minimumSize: const Size.fromHeight(40)),
                              child: const Text('Terima & Proses')),
                          if (status == 'acknowledged' || status == 'in_progress')
                            FilledButton(onPressed: () => _completeMaintenance(m['id']), style: FilledButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(40)),
                              child: const Text('Selesaikan')),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFuelTab() {
    final pending = _fuelLogs.where((f) => f['validation_status'] == 'pending').toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      child: pending.isEmpty
          ? const Center(child: Text('Tidak ada fuel log menunggu validasi'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (_, i) {
                final f = pending[i];
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
                              const Icon(Icons.local_gas_station, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f['vehicle']?['model'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text('${f['liters']} L', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Driver: ${f['driver']?['name'] ?? '-'} | ${f['fuel_type'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                          Text('Rp ${f['total_cost']} | SPBU: ${f['station_name'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(onPressed: () => _rejectFuel(f['id']), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Tolak'))),
                              const SizedBox(width: 12),
                              Expanded(child: FilledButton(onPressed: () => _validateFuel(f['id']), style: FilledButton.styleFrom(backgroundColor: Colors.green), child: const Text('Validasi'))),
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

  IconData _priorityIcon(String p) => switch (p) { 'critical' => Icons.error, 'high' => Icons.warning, _ => Icons.info };
  Color _priorityColor(String p) => switch (p) { 'critical' => Colors.red, 'high' => Colors.orange, 'medium' => Colors.amber, _ => Colors.grey };

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
}
