import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'admin_package_management_screen.dart';
import 'admin_fleet_management_screen.dart';
import 'admin_threshold_screen.dart';

class _MasterItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;

  const _MasterItem(this.icon, this.title, this.subtitle, this.builder);
}

class AdminMasterDataScreen extends StatelessWidget {
  const AdminMasterDataScreen({super.key});

  static const _accent = AppColors.roleAdmin;

  List<_MasterItem> get _items => [
        _MasterItem(
          Icons.inventory_2_outlined,
          'Paket Layanan',
          'Kelola paket, item stok, harga',
          () => const AdminPackageManagementScreen(),
        ),
        _MasterItem(
          Icons.tune_outlined,
          'Threshold Sistem',
          'Batas waktu, toleransi, konfigurasi',
          () => const AdminThresholdScreen(),
        ),
        _MasterItem(
          Icons.local_shipping_outlined,
          'Manajemen Armada',
          'Daftar kendaraan & status',
          () => const AdminFleetManagementScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Master Data',
        accentColor: _accent,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey(item.title),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + index * 50),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassWidget(
                    borderRadius: 16,
                    blurSigma: 14,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.builder()),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: _accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textHint, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
