import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Full-screen alarm overlay with pulsing animation.
/// Used for critical notifications that must bypass do-not-disturb.
class GlassAlarmOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String? orderId;
  final Color accentColor;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const GlassAlarmOverlay({
    super.key,
    required this.title,
    required this.message,
    this.orderId,
    this.accentColor = AppColors.statusDanger,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<GlassAlarmOverlay> createState() => _GlassAlarmOverlayState();
}

class _GlassAlarmOverlayState extends State<GlassAlarmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: 0.95 + (_pulseAnim.value * 0.05),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing icon
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, _) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor.withValues(alpha: _pulseAnim.value * 0.2),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: widget.accentColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.orderId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.orderId!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Tutup'),
                        ),
                      ),
                      if (widget.onAction != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: widget.accentColor,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(widget.actionLabel ?? 'Lihat'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show the alarm overlay as a full-screen dialog.
Future<void> showAlarmOverlay(
  BuildContext context, {
  required String title,
  required String message,
  String? orderId,
  Color accentColor = AppColors.statusDanger,
  VoidCallback? onAction,
  String? actionLabel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GlassAlarmOverlay(
      title: title,
      message: message,
      orderId: orderId,
      accentColor: accentColor,
      onAction: onAction,
      actionLabel: actionLabel,
      onDismiss: () => Navigator.of(ctx).pop(),
    ),
  );
}
