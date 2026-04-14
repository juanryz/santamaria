import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../vendor/screens/vendor_attendance_screen.dart';
import '../../kpi/screens/kpi_dashboard_screen.dart';
import 'gallery_link_screen.dart';
import '../../wage/screens/my_wage_claims_screen.dart';

class TukangFotoDashboardScreen extends StatefulWidget {
  const TukangFotoDashboardScreen({super.key});

  @override
  State<TukangFotoDashboardScreen> createState() => _TukangFotoDashboardScreenState();
}

class _TukangFotoDashboardScreenState extends State<TukangFotoDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  static const _roleColor = AppColors.roleTukangFoto;

  List<dynamic> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/vendor/assignments');
      if (res.data['success'] == true) {
        _assignments = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Tukang Foto',
        accentColor: _roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.brandPrimary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KpiDashboardScreen())),
          ),
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
                  // Stats
                  Row(
                    children: [
                      _statCard('Tugas\nAktif', _assignments.where((a) => a['status'] == 'confirmed' || a['status'] == 'pending').length, Icons.camera_alt, _roleColor),
                      const SizedBox(width: 12),
                      _statCard('Selesai\nBulan Ini', _assignments.where((a) => a['status'] == 'completed').length, Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Menu Upah
                  GlassWidget(
                    borderRadius: 14,
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet, color: _roleColor),
                      title: const Text('Klaim Upah Layanan', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Ajukan & lihat status upah per order'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWageClaimsScreen())),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tugas Mendatang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_assignments.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada tugas')))
                  else
                    ..._assignments.map((a) => _buildAssignmentCard(a)),
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

  Widget _buildAssignmentCard(dynamic a) {
    final order = a['order'] ?? {};
    final status = a['status'] ?? 'pending';

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
                  GlassStatusBadge(label: status, color: status == 'confirmed' ? Colors.green : Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              if (order['deceased_name'] != null) Text('Almarhum: ${order['deceased_name']}', style: const TextStyle(fontSize: 13)),
              if (order['destination_address'] != null) Text('Lokasi: ${order['destination_address']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (order['scheduled_at'] != null) Text('Jadwal: ${order['scheduled_at']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VendorAttendanceScreen(orderId: order['id'] ?? ''),
                      )),
                      icon: const Icon(Icons.fingerprint, size: 16),
                      label: const Text('Presensi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GalleryLinkScreen(orderId: order['id'] ?? '', canAdd: true),
                      )),
                      icon: const Icon(Icons.add_to_drive, size: 16),
                      label: const Text('Galeri'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.roleTukangFoto),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
