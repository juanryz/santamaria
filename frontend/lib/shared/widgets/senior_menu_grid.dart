import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Senior-friendly menu grid untuk dashboard.
///
/// Prinsip design untuk orang tua / awam teknologi:
/// - Icon besar (40 px) di atas label
/// - Label tebal & kontras tinggi (font 14, bold)
/// - Card minimal 100x110 px (mudah di-tap)
/// - Grid 2 kolom (tidak sempit, tidak overwhelming)
/// - Warna per item jelas, tidak pucat
/// - Tap feedback kuat (ripple + scale)
///
/// Usage:
/// ```
/// SeniorMenuGrid(
///   items: [
///     SeniorMenuItem(
///       icon: Icons.receipt_long,
///       label: 'Order',
///       color: AppColors.brandPrimary,
///       onTap: () => Navigator.push(...),
///     ),
///     ...
///   ],
/// )
/// ```
class SeniorMenuGrid extends StatelessWidget {
  final List<SeniorMenuItem> items;
  final int columns;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double? aspectRatio;

  const SeniorMenuGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    // Aspect ratio dihitung berdasarkan jumlah kolom + apakah ada subtitle.
    // 3 kolom (card sempit) → card lebih tinggi (0.85)
    // 2 kolom (card lebar) → hampir square (1.0)
    final hasSubtitle = items.any((i) => i.subtitle != null);
    final effectiveRatio = aspectRatio ?? _defaultRatio(columns, hasSubtitle);

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: effectiveRatio,
      children: items.map((item) => _SeniorMenuCard(item: item)).toList(),
    );
  }

  double _defaultRatio(int cols, bool hasSubtitle) {
    if (cols >= 4) return 0.80;
    if (cols == 3) return hasSubtitle ? 0.82 : 0.92;
    if (cols == 2) return hasSubtitle ? 1.05 : 1.15;
    return 1.3; // 1 kolom (list-like)
  }
}

/// Single menu item definition.
class SeniorMenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;
  final int? badge; // notifikasi count

  const SeniorMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color = AppColors.brandPrimary,
    this.onTap,
    this.badge,
  });
}

class _SeniorMenuCard extends StatefulWidget {
  final SeniorMenuItem item;

  const _SeniorMenuCard({required this.item});

  @override
  State<_SeniorMenuCard> createState() => _SeniorMenuCardState();
}

class _SeniorMenuCardState extends State<_SeniorMenuCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  bool get _hasUpdate => (widget.item.badge ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_hasUpdate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _SeniorMenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadUpdate = (oldWidget.item.badge ?? 0) > 0;
    if (_hasUpdate && !hadUpdate) {
      _pulseController.repeat(reverse: true);
    } else if (!_hasUpdate && hadUpdate) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final disabled = item.onTap == null;

    // Kalau ada update: subtitle override jadi "X baru" dengan warna merah.
    final subtitle = _hasUpdate ? '${item.badge} baru' : item.subtitle;
    final subtitleColor = _hasUpdate
        ? AppColors.statusDanger
        : AppColors.textSecondary;
    final subtitleWeight = _hasUpdate ? FontWeight.w800 : FontWeight.w500;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final scale = (_pressed ? 0.96 : 1.0) *
            (_hasUpdate ? _pulseAnim.value : 1.0);
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(18),
          splashColor: item.color.withValues(alpha: 0.15),
          highlightColor: item.color.withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: disabled
                    ? AppColors.textHint.withValues(alpha: 0.25)
                    : (_hasUpdate
                        ? AppColors.statusDanger.withValues(alpha: 0.50)
                        : item.color.withValues(alpha: 0.20)),
                width: _hasUpdate ? 1.8 : 1.2,
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: (_hasUpdate
                                ? AppColors.statusDanger
                                : item.color)
                            .withValues(alpha: _hasUpdate ? 0.15 : 0.08),
                        blurRadius: _hasUpdate ? 18 : 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon dengan background bulat
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: disabled
                            ? AppColors.textHint.withValues(alpha: 0.1)
                            : item.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 26,
                        color: disabled ? AppColors.textHint : item.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Flexible(
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: subtitleColor,
                            fontWeight: subtitleWeight,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Notification badge (kanan atas) — bigger + bold for elderly
                if (_hasUpdate)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.statusDanger.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.badge! > 99 ? '99+' : item.badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// List-style menu (1 kolom, lebar penuh) — alternatif untuk menu teks
/// panjang atau yang butuh subtitle deskriptif.
///
/// Lebih cocok untuk list action (vs grid yang cocok untuk navigasi utama).
class SeniorMenuList extends StatelessWidget {
  final List<SeniorMenuItem> items;
  final EdgeInsetsGeometry padding;

  const SeniorMenuList({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SeniorMenuListTile(item: item),
                ))
            .toList(),
      ),
    );
  }
}

class _SeniorMenuListTile extends StatelessWidget {
  final SeniorMenuItem item;

  const _SeniorMenuListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final disabled = item.onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: item.color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled
                  ? AppColors.textHint.withValues(alpha: 0.25)
                  : item.color.withValues(alpha: 0.20),
              width: 1.2,
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: disabled
                      ? AppColors.textHint.withValues(alpha: 0.1)
                      : item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: disabled ? AppColors.textHint : item.color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: disabled ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.badge != null && item.badge! > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusDanger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.badge! > 99 ? '99+' : item.badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (!disabled)
                Icon(
                  Icons.chevron_right,
                  color: item.color.withValues(alpha: 0.5),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
