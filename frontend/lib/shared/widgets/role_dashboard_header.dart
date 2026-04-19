import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../modules/auth/screens/unified_login_screen.dart';
import 'glass_widget.dart';
import 'notification_bell.dart';

/// Header pattern seragam untuk SEMUA role dashboard.
///
/// Prinsip:
/// - Role name kecil di atas (UPPERCASE label — identitas)
/// - Greeting + nama user besar bold
/// - Logout button di kanan (glass circle, tap target 48dp)
/// - Optional badge untuk notifikasi/anomali
/// - Optional trailing widget (misal: notif icon)
///
/// Usage:
/// ```
/// RoleDashboardHeader(
///   roleLabel: 'Owner Portal',
///   roleColor: AppColors.roleOwner,
///   greeting: 'Selamat pagi',
///   userName: 'Budi',
///   badges: [
///     HeaderBadge(label: '3 Anomali', color: AppColors.statusDanger),
///   ],
/// )
/// ```
class RoleDashboardHeader extends StatelessWidget {
  final String roleLabel;
  final Color roleColor;
  final String? greeting;
  final String userName;
  final List<HeaderBadge> badges;
  final List<Widget>? actions;
  final bool showLogout;
  final List<DashboardNotification>? notifications;

  const RoleDashboardHeader({
    super.key,
    required this.roleLabel,
    required this.roleColor,
    required this.userName,
    this.greeting,
    this.badges = const [],
    this.actions,
    this.showLogout = true,
    this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: role label + name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (greeting != null) ...[
                      Text(
                        greeting!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right: bell + actions + logout
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (notifications != null)
                    NotificationBell(
                      notifications: notifications!,
                      accentColor: roleColor,
                    ),
                  if (actions != null) ...actions!,
                  if (showLogout)
                    GlassWidget(
                      borderRadius: 14,
                      blurSigma: 10,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(12),
                      onTap: () => _confirmLogout(context),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Badges (kalau ada)
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((b) => _buildBadge(b)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(HeaderBadge b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: b.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: b.color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.icon != null) ...[
            Icon(b.icon, color: b.color, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            b.label,
            style: TextStyle(
              color: b.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Keluar?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Anda akan keluar dari aplikasi. Untuk masuk lagi, silakan login.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              minimumSize: const Size(100, 48),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final nav = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      (_) => false,
    );
  }
}

/// Badge notifikasi untuk header (misal: anomali count, pending task).
class HeaderBadge {
  final String label;
  final Color color;
  final IconData? icon;

  const HeaderBadge({
    required this.label,
    required this.color,
    this.icon,
  });
}

/// Stat card pattern untuk dashboard — 1 angka besar + label di bawah.
/// Biar seragam dipakai oleh semua role.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final String? trend; // "↑ 12%" atau "Rp 500rb"

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = AppColors.brandPrimary,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    // Pakai SizedBox fixed height (bukan Spacer + Column.max) — supaya layout
    // tidak crash saat parent kasih unbounded height (contoh: dalam ScrollView).
    // Semua 3 cards tetap sejajar karena tinggi fix 120.
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header row: icon kiri + trend kanan
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              if (icon != null && trend != null) const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          // Value + label di bagian bawah
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
