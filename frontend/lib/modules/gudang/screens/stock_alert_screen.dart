import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class StockAlertScreen extends StatefulWidget {
  const StockAlertScreen({super.key});

  @override
  State<StockAlertScreen> createState() => _StockAlertScreenState();
}

class _StockAlertScreenState extends State<StockAlertScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/stock-alerts', queryParameters: {'resolved': 'false'});
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _alerts = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resolve(String id) async {
    try {
      await _api.dio.put('/gudang/stock-alerts/$id/resolve');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert diselesaikan')));
    } catch (_) {}
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'out_of_stock': return Colors.red;
      case 'low_stock': return Colors.orange;
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Alert Stok', accentColor: AppColors.roleGudang),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
                ? const Center(child: Text('Tidak ada alert stok'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) {
                      final a = _alerts[i];
                      final type = a['alert_type'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(Icons.warning_amber, color: _alertColor(type), size: 32),
                            title: Text(a['stock_item']?['item_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['message'] ?? '', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Stok: ${a['current_quantity']} / Min: ${a['minimum_quantity']}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onPressed: () => _resolve(a['id']),
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
