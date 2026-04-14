import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_widget.dart';

/// Bottom sheet glass — backdrop blur + white glass container.
Future<T?> showGlassModal<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  Color accentColor = AppColors.brandPrimary,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassWidget(
          borderRadius: 28,
          blurSigma: 30,
          tint: AppColors.glassWhite,
          borderColor: accentColor.withValues(alpha: 0.20),
          elevation: 12,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              child,
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    ),
  );
}
