import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_widget.dart';

/// App bar dengan efek liquid glass — blur + tint putih.
/// Teks & ikon berwarna gelap (untuk background putih).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color accentColor;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    super.key,
    required this.title,
    this.accentColor = AppColors.brandPrimary,
    this.actions,
    this.showBack = false,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect back button: show if Navigator can pop (unless explicitly disabled)
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = leading == null && (showBack || canPop);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.glassWhite,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: accentColor.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (leading != null)
                        leading!
                      else if (shouldShowBack)
                        GlassWidget(
                          borderRadius: 12,
                          blurSigma: 10,
                          tint: accentColor.withValues(alpha: 0.08),
                          borderColor: accentColor.withValues(alpha: 0.20),
                          padding: const EdgeInsets.all(8),
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: accentColor,
                          ),
                        ),
                      if (shouldShowBack || leading != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
                ?bottom,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 8 + (bottom?.preferredSize.height ?? 0));
}

/// Icon button untuk GlassAppBar — glass circle style.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.textPrimary,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GlassWidget(
        borderRadius: 12,
        blurSigma: 10,
        tint: color.withValues(alpha: 0.08),
        borderColor: color.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        onTap: onPressed,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
