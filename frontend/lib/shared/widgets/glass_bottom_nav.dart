import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_widget.dart';

class GlassNavItem {
  final IconData icon;
  final String label;
  const GlassNavItem({required this.icon, required this.label});
}

/// Floating bottom navigation bar dengan efek liquid glass.
/// Gunakan dalam Stack sebagai Positioned(bottom: 16, left: 24, right: 24).
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;
  final Color accentColor;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.accentColor = AppColors.brandPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: GlassWidget(
        borderRadius: 28,
        blurSigma: 30,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = currentIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive ? accentColor : AppColors.textSecondary,
                      size: 22,
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
