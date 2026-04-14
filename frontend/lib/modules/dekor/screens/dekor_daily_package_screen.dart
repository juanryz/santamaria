import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class DekorDailyPackageScreen extends StatefulWidget {
  final String orderId;
  const DekorDailyPackageScreen({super.key, required this.orderId});

  @override
  State<DekorDailyPackageScreen> createState() => _DekorDailyPackageScreenState();
}

class _DekorDailyPackageScreenState extends State<DekorDailyPackageScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _packages = [];
  List<dynamic> _masterItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/dekor/orders/${widget.orderId}/daily-package'),
        _api.dio.get('/admin/master/dekor-items'),
      ]);
      if (results[0].data['success'] == true) {
        _packages = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _masterItems = List<dynamic>.from(results[1].data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createPackage() async {
    final lines = _masterItems.map((m) => {
      'dekor_master_id': m['id'],
      'anggaran_pendapatan': 0,
      'qty': 1,
    }).toList();

    try {
      await _api.dio.post('/dekor/orders/${widget.orderId}/daily-package', data: {
        'form_date': DateTime.now().toIso8601String().split('T')[0],
        'lines': lines,
      });
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Paket Harian La Fiore', accentColor: AppColors.roleDekor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roleDekor,
        onPressed: _createPackage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _packages.isEmpty
                ? const Center(child: Text('Belum ada paket harian'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _packages.length,
                    itemBuilder: (_, i) {
                      final p = _packages[i];
                      final lines = List<dynamic>.from(p['lines'] ?? []);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassWidget(
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('Tanggal: ${p['form_date'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Text('Rp ${p['total_biaya_aktual'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.roleDekor)),
                                  ],
                                ),
                                if (p['rumah_duka'] != null) Text('Rumah Duka: ${p['rumah_duka']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 12),
                                ...lines.map((l) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(l['dekor_master']?['item_name'] ?? '-', style: const TextStyle(fontSize: 12))),
                                          Expanded(child: Text('${l['qty'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                          Expanded(flex: 2, child: Text('Rp ${l['biaya_supplier_1'] ?? '-'}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12))),
                                        ],
                                      ),
                                    )),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Anggaran: Rp ${p['total_anggaran'] ?? 0}', style: const TextStyle(fontSize: 12)),
                                    Text(
                                      'Selisih: Rp ${p['selisih'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (p['selisih'] ?? 0) >= 0 ? Colors.green : Colors.red,
                                      ),
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
      ),
    );
  }
}
