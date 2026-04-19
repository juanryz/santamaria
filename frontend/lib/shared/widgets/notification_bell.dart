import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'glass_widget.dart';

/// Notification bell dengan badge untuk dipasang di header dashboard.
///
/// - Icon bel besar (22dp) — mudah dilihat senior
/// - Badge merah bulat + angka (28dp min)
/// - Pulse animation saat ada notif baru
/// - Tap → buka panel list notif
///
/// Usage:
/// ```
/// NotificationBell(
///   notifications: [
///     DashboardNotification(
///       icon: Icons.receipt_long,
///       title: 'Order Baru',
///       message: 'Ada 3 order baru masuk',
///       timestamp: DateTime.now(),
///       color: AppColors.brandPrimary,
///       onTap: () { ... },
///     ),
///   ],
/// )
/// ```
class NotificationBell extends StatefulWidget {
  final List<DashboardNotification> notifications;
  final Color accentColor;

  const NotificationBell({
    super.key,
    required this.notifications,
    this.accentColor = AppColors.brandPrimary,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleAnim;

  int get _count => widget.notifications.length;
  bool get _hasNotifs => _count > 0;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _wobbleAnim = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.elasticInOut),
    );
    if (_hasNotifs) _wobbleController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasNotifs && !_wobbleController.isAnimating) {
      _wobbleController.repeat(reverse: true);
    } else if (!_hasNotifs) {
      _wobbleController.stop();
      _wobbleController.value = 0;
    }
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  Future<void> _openPanel() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NotificationPanel(
        notifications: widget.notifications,
        accentColor: widget.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      borderRadius: 14,
      blurSigma: 10,
      tint: _hasNotifs
          ? AppColors.statusDanger.withValues(alpha: 0.10)
          : AppColors.glassWhite,
      borderColor: _hasNotifs
          ? AppColors.statusDanger.withValues(alpha: 0.35)
          : AppColors.glassBorder,
      padding: const EdgeInsets.all(12),
      onTap: _openPanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _wobbleAnim,
            builder: (_, child) => Transform.rotate(
              angle: _hasNotifs ? _wobbleAnim.value : 0,
              child: child,
            ),
            child: Icon(
              _hasNotifs
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: _hasNotifs
                  ? AppColors.statusDanger
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (_hasNotifs)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints:
                    const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _count > 99 ? '99+' : _count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Model single notification item untuk bell panel.
class DashboardNotification {
  final IconData icon;
  final String title;
  final String message;
  final DateTime? timestamp;
  final Color color;
  final VoidCallback? onTap;

  const DashboardNotification({
    required this.icon,
    required this.title,
    required this.message,
    this.timestamp,
    this.color = AppColors.brandPrimary,
    this.onTap,
  });
}

/// Bottom sheet panel — list semua notification.
class _NotificationPanel extends StatelessWidget {
  final List<DashboardNotification> notifications;
  final Color accentColor;

  const _NotificationPanel({
    required this.notifications,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifikasi Terbaru',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${notifications.length} update baru',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 26),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Flexible(
            child: notifications.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _buildItem(ctx, notifications[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Tidak ada notifikasi baru',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Semua sudah up to date',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext ctx, DashboardNotification n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: n.onTap == null
            ? null
            : () {
                Navigator.pop(ctx);
                n.onTap!();
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.color.withValues(alpha: 0.20),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: n.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(n.icon, color: n.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (n.timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(n.timestamp!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (n.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: n.color.withValues(alpha: 0.6),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
