import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import 'coffin_order_detail_screen.dart';
import 'coffin_order_form_screen.dart';

class CoffinOrderListScreen extends StatefulWidget {
  const CoffinOrderListScreen({super.key});

  @override
  State<CoffinOrderListScreen> createState() => _CoffinOrderListScreenState();
}

class _CoffinOrderListScreenState extends State<CoffinOrderListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/coffin-orders');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _orders = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'busa_process': case 'amplas_process': return Colors.blue;
      case 'busa_done': case 'amplas_done': return Colors.teal;
      case 'qc_pending': return Colors.orange;
      case 'qc_passed': return Colors.green;
      case 'qc_failed': return Colors.red;
      case 'delivered': return AppColors.statusSuccess;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Workshop Peti', accentColor: AppColors.roleGudang),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.roleGudang,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffinOrderFormScreen()));
          _loadData();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(child: Text('Belum ada order peti'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(o['coffin_order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Kode: ${o['kode_peti'] ?? '-'} | ${o['finishing_type'] ?? '-'}'),
                                const SizedBox(height: 8),
                                GlassStatusBadge(label: o['status'] ?? '', color: _statusColor(o['status'] ?? '')),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CoffinOrderDetailScreen(coffinOrderId: o['id']),
                              ));
                              _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
