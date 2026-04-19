import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'super_admin_user_list_screen.dart';
import 'super_admin_master_data_screen.dart';
import 'super_admin_role_management_screen.dart';
import 'super_admin_freelance_worker_screen.dart';
import '../../admin/screens/admin_documentation_screen.dart';
import '../../../shared/widgets/change_password_dialog.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  static const _roleColor = AppColors.roleSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?['name'] ?? 'Super Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Super Admin',
                              style: TextStyle(
                                  color: _roleColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Halo, $userName',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Spacer(),
                      GlassWidget(
                        borderRadius: 12,
                        blurSigma: 10,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(8),
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const UnifiedLoginScreen()),
                            (_) => false,
                          );
                        },
                        child: const Icon(Icons.logout,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      GlassWidget(
                        borderRadius: 12,
                        blurSigma: 10,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(8),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ChangePasswordDialog(
                              apiClient: ApiClient(),
                              isPin: false,
                            ),
                          );
                        },
                        child: const Icon(Icons.settings_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kendali penuh atas seluruh sistem Santa Maria.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  Text('Manajemen Akun',
                      style: TextStyle(
                          color: _roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    context,
                    icon: Icons.manage_accounts_rounded,
                    title: 'Kelola Semua Pengguna',
                    subtitle:
                        'Buat, edit, nonaktifkan akun internal & vendor',
                    color: _roleColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SuperAdminUserListScreen(
                              apiClient: ApiClient())),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMenuCard(
                    context,
                    icon: Icons.dataset_outlined,
                    title: 'Master Data',
                    subtitle: 'Kelola 16 entitas data master sistem',
                    color: _roleColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SuperAdminMasterDataScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMenuCard(
                    context,
                    icon: Icons.badge_outlined,
                    title: 'Manajemen Role',
                    subtitle: 'Tambah, edit, dan kelola role kustom sistem',
                    color: _roleColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SuperAdminRoleManagementScreen(
                              apiClient: ApiClient())),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // v1.40 memory — Super Admin handle photo documentation
                  // (tukang foto kasih flashdisk, Super Admin upload manual ke email folder)
                  _buildMenuCard(
                    context,
                    icon: Icons.photo_library_rounded,
                    title: 'Dokumentasi Foto',
                    subtitle:
                        'Upload foto & link galeri dari flashdisk tukang foto',
                    color: _roleColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDocumentationScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // v1.40 memory — Super Admin handle freelance workers
                  // (tukang jaga, tukang angkat peti, musisi)
                  _buildMenuCard(
                    context,
                    icon: Icons.groups_rounded,
                    title: 'Pekerja Lepas',
                    subtitle:
                        'Kelola tukang jaga, tukang angkat peti, dan musisi',
                    color: _roleColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const SuperAdminFreelanceWorkerScreen()),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassWidget(
                    borderRadius: 16,
                    blurSigma: 16,
                    tint: _roleColor.withValues(alpha: 0.05),
                    borderColor: _roleColor.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: _roleColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Panduan Super Admin',
                                style: TextStyle(
                                    color: _roleColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Super Admin membuat semua akun internal dan vendor.\n'
                          '• Password ditentukan saat pembuatan dan wajib diberikan langsung ke pengguna.\n'
                          '• Akun konsumen dibuat sendiri oleh konsumen via registrasi mandiri.\n'
                          '• Super Admin tidak dapat dilihat atau diedit oleh role lain.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
