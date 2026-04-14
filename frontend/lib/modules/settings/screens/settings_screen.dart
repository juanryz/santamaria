import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/biometric_setting_tile.dart';
import '../../../shared/widgets/change_password_dialog.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../kpi/screens/kpi_dashboard_screen.dart';
import '../../attendance/screens/my_attendance_screen.dart';

/// Universal settings screen — available to ALL roles.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?['role'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Pengaturan', accentColor: AppColors.roleColor(role)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          GlassWidget(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.roleColor(role).withValues(alpha: 0.15),
                    child: Text(
                      (user?['name'] ?? '?')[0].toUpperCase(),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.roleColor(role)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?['name'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(user?['email'] ?? user?['phone'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.roleColor(role).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(role.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.roleColor(role))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security section
          const _SectionHeader('Keamanan'),
          const SizedBox(height: 8),
          const BiometricSettingTile(),
          const SizedBox(height: 8),
          GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.brandPrimary),
              title: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(context: context, builder: (_) => ChangePasswordDialog(apiClient: ApiClient())),
            ),
          ),
          const SizedBox(height: 20),

          // Quick links
          const _SectionHeader('Lainnya'),
          const SizedBox(height: 8),
          GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.brandPrimary),
              title: const Text('KPI Saya', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KpiDashboardScreen())),
            ),
          ),
          const SizedBox(height: 8),
          GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: AppColors.brandPrimary),
              title: const Text('Riwayat Presensi', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAttendanceScreen())),
            ),
          ),
          const SizedBox(height: 8),
          GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.brandPrimary),
              title: const Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Santa Maria Funeral Organizer v1.27', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Santa Maria FO',
                applicationVersion: 'v1.27',
                applicationLegalese: 'CV Santa Maria Funeral Organizer\nSemarang, Indonesia',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showGlassConfirm(
                  context: context,
                  title: 'Keluar?',
                  message: 'Anda yakin ingin keluar dari aplikasi?',
                  confirmLabel: 'Keluar',
                  isDanger: true,
                );

                if (confirm == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  await BiometricService.instance.disable();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                      (_) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.statusDanger),
              label: const Text('Keluar', style: TextStyle(color: AppColors.statusDanger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusDanger),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppColors.textHint,
      ),
    );
  }
}
