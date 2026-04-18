import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'security_incident_screen.dart';
import 'security_key_screen.dart';
import 'security_patrol_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class SecurityHomeScreen extends StatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  State<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends State<SecurityHomeScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = Color(0xFF636E72);

  bool _isLoading = true;
  int _incidentsToday = 0;
  int _keysOut = 0;
  int _patrolsPending = 0;
  bool _clockedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/security/dashboard');
      if (res.data['success'] == true) {
        final d = res.data['data'] ?? {};
        _incidentsToday = d['incidents_today'] ?? 0;
        _keysOut = d['keys_out'] ?? 0;
        _patrolsPending = d['patrols_pending'] ?? 0;
        _clockedIn = d['clocked_in'] == true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Security',
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
                  // Clock-in status
                  GlassWidget(
                    borderRadius: 14,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _clockedIn ? Icons.check_circle : Icons.access_time,
                            color: _clockedIn ? AppColors.statusSuccess : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _clockedIn ? 'Sudah Clock In' : 'Belum Clock In',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _clockedIn ? AppColors.statusSuccess : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: [
                      _statCard('Insiden\nHari Ini', _incidentsToday, Icons.report_problem, Colors.red),
                      const SizedBox(width: 12),
                      _statCard('Kunci\nKeluar', _keysOut, Icons.vpn_key, Colors.orange),
                      const SizedBox(width: 12),
                      _statCard('Patroli\nPending', _patrolsPending, Icons.security, _roleColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _menuTile(Icons.report_problem, 'Lapor Insiden', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityIncidentScreen()));
                  }),
                  _menuTile(Icons.vpn_key, 'Serah Terima Kunci', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityKeyScreen()));
                  }),
                  _menuTile(Icons.shield, 'Mulai Patroli', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPatrolScreen()));
                  }),
                  _menuTile(Icons.history, 'Riwayat Insiden', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityIncidentScreen()));
                  }),
                  _menuTile(Icons.event_available, 'Cuti & Izin Saya', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLeavesScreen()));
                  }),
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

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        child: ListTile(
          leading: Icon(icon, color: _roleColor),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
