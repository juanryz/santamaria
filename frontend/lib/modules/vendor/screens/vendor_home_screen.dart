import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

/// Generic home screen for vendor roles (pemuka_agama, konsumsi, etc.)
/// Shows their order assignments and attendance status.
class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _assignments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/vendor/assignments');
      if (!mounted) return;
      setState(() {
        _assignments = (res.data['data'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final role = user?['role'] ?? 'vendor';
    final name = user?['name'] ?? 'Vendor';
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Halo, $name',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    GlassWidget(
                      borderRadius: 12,
                      blurSigma: 10,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(8),
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await context.read<AuthProvider>().logout();
                        if (!mounted) return;
                        nav.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                          (_) => false,
                        );
                      },
                      child: const Icon(Icons.logout, color: AppColors.textSecondary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats
                GlassWidget(
                  borderRadius: 16,
                  blurSigma: 12,
                  tint: roleColor.withValues(alpha: 0.08),
                  borderColor: roleColor.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Tugas', _assignments.length.toString(), roleColor),
                      _stat('Aktif', _assignments.where((a) => a['status'] == 'confirmed' || a['status'] == 'present').length.toString(), AppColors.statusSuccess),
                      _stat('Selesai', _assignments.where((a) => a['status'] == 'completed').length.toString(), AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Assignments
                Text('Tugas Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: roleColor)),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(child: Text(_error!, style: const TextStyle(color: AppColors.statusDanger)))
                else if (_assignments.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Text('Belum ada tugas', style: TextStyle(color: AppColors.textHint)),
                  ))
                else
                  ..._assignments.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassWidget(
                      borderRadius: 16,
                      blurSigma: 12,
                      tint: AppColors.glassWhite,
                      borderColor: roleColor.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment, color: roleColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                a['order']?['order_number'] ?? 'Order',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(a['status']).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(a['status']),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(a['status'])),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (a['activity_description'] != null)
                            Text(a['activity_description'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          if (a['scheduled_date'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Jadwal: ${a['scheduled_date']} ${a['scheduled_time'] ?? ''}',
                                style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _statusColor(String? status) => switch (status) {
    'assigned' => AppColors.textHint,
    'confirmed' => AppColors.statusInfo,
    'present' => AppColors.statusSuccess,
    'completed' => AppColors.textSecondary,
    'declined' || 'no_show' => AppColors.statusDanger,
    _ => AppColors.textHint,
  };

  String _statusLabel(String? status) => switch (status) {
    'assigned' => 'Menunggu',
    'confirmed' => 'Dikonfirmasi',
    'present' => 'Hadir',
    'completed' => 'Selesai',
    'declined' => 'Ditolak',
    'no_show' => 'Tidak Hadir',
    _ => status ?? '-',
  };
}
