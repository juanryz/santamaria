import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class DriverTripLogScreen extends StatefulWidget {
  const DriverTripLogScreen({super.key});

  @override
  State<DriverTripLogScreen> createState() => _DriverTripLogScreenState();
}

class _DriverTripLogScreenState extends State<DriverTripLogScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/driver/vehicle-trip-logs');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _logs = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createLog() async {
    // Simple creation dialog
    final atasNamaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final tujuanCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota Perjalanan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: atasNamaCtrl, decoration: const InputDecoration(labelText: 'Atas Nama *')),
              const SizedBox(height: 8),
              TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat Jemput *')),
              const SizedBox(height: 8),
              TextField(controller: tujuanCtrl, decoration: const InputDecoration(labelText: 'Tujuan *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat')),
        ],
      ),
    );

    if (result == true && atasNamaCtrl.text.isNotEmpty) {
      try {
        await _api.dio.post('/driver/vehicle-trip-logs', data: {
          'vehicle_id': '', // Will need vehicle selection
          'atas_nama': atasNamaCtrl.text,
          'alamat_penjemputan': alamatCtrl.text,
          'tujuan': tujuanCtrl.text,
          'waktu_pemakaian': DateTime.now().toIso8601String(),
        });
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Nota Mobil Jenazah', accentColor: AppColors.roleDriver),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roleDriver,
        onPressed: _createLog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? const Center(child: Text('Belum ada nota perjalanan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final l = _logs[i];
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
                                    const Icon(Icons.directions_car, color: AppColors.roleDriver, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(l['nota_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Atas Nama: ${l['atas_nama'] ?? '-'}'),
                                Text('Dari: ${l['alamat_penjemputan'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                Text('Tujuan: ${l['tujuan'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                if (l['km_total'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('KM: ${l['km_total']} | Biaya: Rp ${l['total_biaya'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
