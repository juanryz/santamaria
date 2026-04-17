import 'package:flutter/material.dart';

/// A button that shows a spinner + [loadingLabel] when [isLoading] is true,
/// and a normal button with [label] (+ optional [icon]) otherwise.
/// Automatically disabled while loading.
class LoadingButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isFullWidth;

  const LoadingButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.isLoading = false,
    required this.onPressed,
    this.color,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary;
    final child = SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLoading
              ? [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  if (loadingLabel != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      loadingLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ]
              : [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
        ),
      ),
    );
    return child;
  }
}
