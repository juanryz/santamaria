import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/unified_login_screen.dart';

class ViewerDashboardScreen extends StatefulWidget {
  const ViewerDashboardScreen({super.key});

  @override
  State<ViewerDashboardScreen> createState() => _ViewerDashboardScreenState();
}

class _ViewerDashboardScreenState extends State<ViewerDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  static const _roleColor = AppColors.roleViewer;

  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      try {
        final res = await _api.dio.get('/owner/orders');
        if (res.data['success'] == true) {
          _orders = List<dynamic>.from(res.data['data'] ?? []);
        }
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders.where((o) => o['status'] == 'pending').length;
    final active = _orders.where((o) => o['status'] == 'confirmed' || o['status'] == 'in_progress').length;
    final completed = _orders.where((o) => o['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Viewer',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.brandPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Read-only notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Mode read-only. Anda hanya dapat melihat data.', style: TextStyle(fontSize: 12, color: Colors.blue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('Pending', pending, Icons.hourglass_empty, Colors.orange),
                      const SizedBox(width: 12),
                      _statCard('Aktif', active, Icons.play_circle, Colors.blue),
                      const SizedBox(width: 12),
                      _statCard('Selesai', completed, Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Semua Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._orders.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassWidget(
                          borderRadius: 12,
                          child: ListTile(
                            title: Text(o['order_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${o['deceased_name'] ?? '-'} | ${o['destination_address'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                            trailing: GlassStatusBadge(label: o['status'] ?? '', color: _roleColor),
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
