import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

export '../constants/app_colors.dart';

class AppTheme {
  // Kept for any code still referencing AppTheme.accent / AppTheme.primary
  static const Color primary    = AppColors.brandPrimary;
  static const Color accent     = AppColors.brandPrimary;
  static const Color background = AppColors.background;
  static const Color surface    = AppColors.surfaceWhite;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
        surface: AppColors.surfaceWhite,
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandSecondary,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      // Use plain TextStyle (inherit: true by default) to prevent TextStyle.lerp
      // assertion errors during button/widget animations caused by GoogleFonts
      // producing inherit:false styles via interTextTheme().
      // Senior-friendly typography — semua naik 1-2 step
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34, // ↑ 32
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26, // ↑ 24
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, // ↑ 18
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17, // ↑ 16
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 17, // ↑ 16 — body default lebih besar
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15, // ↑ 14
          color: AppColors.textPrimary, // ↑ kontras (textSecondary → textPrimary)
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 16, // ↑ 15
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 13, // ↑ 11 (senior bisa baca)
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, // ↑ kontras (textHint → textSecondary)
          letterSpacing: 0.3,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60, // ↑ default 56, lebih lega untuk senior
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20, // ↑ 18
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 26, // ↑ default 24
        ),
      ),

      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Senior-friendly input: tinggi 56dp, text 16px, border lebih tebal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textHint, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.7), // ↑ kontras
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.statusDanger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.statusDanger, width: 2.5),
        ),
        // Text di dalam input
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary, // ↑ kontras
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.brandPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: const TextStyle(
          color: AppColors.statusDanger,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Senior-friendly button: min 56dp, font 16
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textOnColor,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56), // ↑ 52
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16, // ↑ 15
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSoft,
        selectedColor: AppColors.brandPrimary,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14, // ↑ 13
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: AppColors.textHint.withValues(alpha: 0.4)),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.textHint.withValues(alpha: 0.2),
        thickness: 1,
      ),

      // ── Senior-friendly Dialog theme ──────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF2FFFFFF), // 95% white (↑ kontras)
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 20, // ↑ 17
          fontWeight: FontWeight.w800,
          color: AppColors.brandPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16, // ↑ 14
          color: AppColors.textPrimary, // ↑ kontras
          height: 1.5,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── SnackBar senior-friendly ──────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(
          fontSize: 15, // ↑ default 14
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        actionTextColor: Colors.white,
      ),

      // ── Glass-themed BottomSheet ───────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF0FFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.textHint,
        dragHandleSize: Size(40, 4),
      ),

      // ── FilledButton — senior size 52dp ─────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── TextButton — tap target 48dp minimum ────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── DropdownMenu styling ───────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  // Alias for backwards compatibility
  static ThemeData get darkTheme => lightTheme;
}

/// GlassContainer — backwards-compatible alias for GlassWidget.
/// Dipake di banyak screen yang belum dimigrasi ke GlassWidget.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Object? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16,
    this.opacity = 0.7, // putih 70% = glassWhite
    this.borderRadius = 20.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius is BorderRadiusGeometry
        ? borderRadius as BorderRadiusGeometry
        : BorderRadius.circular((borderRadius as num).toDouble());

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: br,
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
