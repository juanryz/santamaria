import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Komponen glass dasar — BackdropFilter blur + white/tinted container.
/// Digunakan untuk card, modal, nav bar, FAB, dll.
class GlassWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color tint;
  final Color borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double elevation;
  final VoidCallback? onTap;

  const GlassWidget({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurSigma = 16.0,
    this.tint = AppColors.glassWhite,
    this.borderColor = AppColors.glassBorder,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    Widget glass = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: br,
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: AppColors.glassShadow,
                      blurRadius: elevation * 4,
                      spreadRadius: elevation * 0.5,
                      offset: Offset(0, elevation * 2),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      glass = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: glass,
        ),
      );
    }

    return Container(margin: margin, child: glass);
  }
}

/// Variasi GlassWidget dengan tint warna per role.
class GlassRoleWidget extends StatelessWidget {
  final Widget child;
  final Color roleColor;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const GlassRoleWidget({
    super.key,
    required this.child,
    required this.roleColor,
    this.borderRadius = 20.0,
    this.blurSigma = 16.0,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      tint: roleColor.withValues(alpha: 0.12),
      borderColor: roleColor.withValues(alpha: 0.25),
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}
