import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable empty/error state widgets with consistent design.

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  /// Convenience: if [actionLabel] and [onAction] are provided (and [action] is null),
  /// a default FilledButton is rendered.
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container lebih besar untuk senior
            Container(
              width: 112, height: 112, // ↑ 80
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandSecondary.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 56, color: AppColors.brandSecondary), // ↑ 40
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18, // ↑ 16
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 15, // ↑ 13
                  color: AppColors.textSecondary, // ↑ kontras (textHint → textSecondary)
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 22),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  minimumSize: const Size(0, 56),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, this.message = 'Terjadi kesalahan', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: message,
      subtitle: 'Periksa koneksi internet Anda dan coba lagi.',
      action: onRetry != null
          ? FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
            )
          : null,
    );
  }
}

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'Tidak Ada Koneksi Internet',
      subtitle: 'Pastikan perangkat terhubung ke internet.',
      action: onRetry != null
          ? OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            )
          : null,
    );
  }
}
