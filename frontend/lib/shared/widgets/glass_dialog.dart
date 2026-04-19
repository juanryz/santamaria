import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Themed dialog yang konsisten dengan design system Glass Santa Maria.
/// Menggantikan AlertDialog bawaan yang tidak sesuai tema.
///
/// Usage:
///   showGlassDialog(context: context, title: 'Judul', content: ..., actions: [...]);
///   showGlassConfirm(context: context, title: 'Hapus?', message: 'Yakin?', confirmLabel: 'Hapus', onConfirm: () {});

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required String title,
  Widget? content,
  List<Widget>? actions,
  Color accentColor = AppColors.brandPrimary,
  bool barrierDismissible = true,
  bool actionsVertical = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black45, // lebih gelap, fokus lebih kuat
    builder: (ctx) => _GlassDialogWidget(
      title: title,
      content: content,
      actions: actions,
      accentColor: accentColor,
      actionsVertical: actionsVertical,
    ),
  );
}

/// Shortcut for simple confirm dialog.
/// Senior-friendly: teks & tombol besar, tombol vertikal (primary di atas),
/// icon untuk tiap aksi biar jelas.
Future<bool> showGlassConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  Color confirmColor = AppColors.brandPrimary,
  bool isDanger = false,
  IconData? icon,
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    title: title,
    accentColor: isDanger ? Colors.red : confirmColor,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 48,
            color: isDanger ? Colors.red : confirmColor,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16, // ↑ 14 → 16 (senior-friendly)
            color: AppColors.textPrimary, // ↑ kontras lebih tinggi
            height: 1.5,
          ),
        ),
      ],
    ),
    actions: [
      // Primary action di atas, full-width — dominant
      GlassDialogButton(
        label: confirmLabel,
        filled: true,
        color: isDanger ? Colors.red : confirmColor,
        fullWidth: true,
        onPressed: () => Navigator.pop(context, true),
      ),
      // Secondary action di bawah
      GlassDialogButton(
        label: cancelLabel,
        fullWidth: true,
        onPressed: () => Navigator.pop(context, false),
      ),
    ],
    actionsVertical: true,
  );
  return result ?? false;
}

/// Shortcut untuk info dialog (tanpa konfirmasi, hanya tombol OK).
Future<void> showGlassInfo({
  required BuildContext context,
  required String title,
  required String message,
  IconData icon = Icons.info_outline,
  Color accentColor = AppColors.brandPrimary,
}) async {
  await showGlassDialog<void>(
    context: context,
    title: title,
    accentColor: accentColor,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: accentColor),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    ),
    actions: [
      GlassDialogButton(
        label: 'Mengerti',
        filled: true,
        color: accentColor,
        fullWidth: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
    actionsVertical: true,
  );
}

/// Shortcut feedback sukses — auto-dismiss 2 detik + tombol OK.
Future<void> showGlassSuccess({
  required BuildContext context,
  required String message,
  String? title,
}) async {
  await showGlassDialog<void>(
    context: context,
    title: title ?? 'Berhasil',
    accentColor: AppColors.statusSuccess,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 56, color: AppColors.statusSuccess),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    ),
    actions: [
      GlassDialogButton(
        label: 'OK',
        filled: true,
        color: AppColors.statusSuccess,
        fullWidth: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
    actionsVertical: true,
  );
}

/// Shortcut feedback error.
Future<void> showGlassError({
  required BuildContext context,
  required String message,
  String? title,
}) async {
  await showGlassDialog<void>(
    context: context,
    title: title ?? 'Gagal',
    accentColor: AppColors.statusDanger,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 56, color: AppColors.statusDanger),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    ),
    actions: [
      GlassDialogButton(
        label: 'Tutup',
        filled: true,
        color: AppColors.statusDanger,
        fullWidth: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
    actionsVertical: true,
  );
}

/// Shortcut for input dialog.
Future<String?> showGlassInput({
  required BuildContext context,
  required String title,
  String? hintText,
  String? initialValue,
  String confirmLabel = 'Simpan',
  int maxLines = 1,
  Color accentColor = AppColors.brandPrimary,
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showGlassDialog<String>(
    context: context,
    title: title,
    content: GlassTextField(
      controller: controller,
      hintText: hintText,
      maxLines: maxLines,
      accentColor: accentColor,
    ),
    actions: [
      GlassDialogButton(
        label: 'Batal',
        onPressed: () => Navigator.pop(context),
      ),
      GlassDialogButton(
        label: confirmLabel,
        filled: true,
        color: accentColor,
        onPressed: () => Navigator.pop(context, controller.text),
      ),
    ],
  );
  controller.dispose();
  return result;
}

/// Themed bottom sheet.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  Color accentColor = AppColors.brandPrimary,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GlassBottomSheetWidget(
      title: title,
      accentColor: accentColor,
      child: child,
    ),
  );
}

// ─── Internal Widgets ──────────────────────────────────────────────

class _GlassDialogWidget extends StatelessWidget {
  final String title;
  final Widget? content;
  final List<Widget>? actions;
  final Color accentColor;
  final bool actionsVertical;

  const _GlassDialogWidget({
    required this.title,
    this.content,
    this.actions,
    this.accentColor = AppColors.brandPrimary,
    this.actionsVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF), // ↑ 95% white, kontras lebih
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(alpha: 0.20),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header — lebih tinggi, font lebih besar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    border: Border(
                      bottom: BorderSide(
                        color: accentColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20, // ↑ 17 → 20 (senior-friendly)
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                if (content != null)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: content,
                    ),
                  ),
                // Actions
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: actionsVertical
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!
                                .expand((a) => [a, const SizedBox(height: 10)])
                                .toList()
                              ..removeLast(),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions!
                                .expand((a) => [a, const SizedBox(width: 10)])
                                .toList()
                              ..removeLast(),
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

class _GlassBottomSheetWidget extends StatelessWidget {
  final String? title;
  final Color accentColor;
  final Widget child;

  const _GlassBottomSheetWidget({
    this.title,
    this.accentColor = AppColors.brandPrimary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xE6FFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
              left: BorderSide(color: AppColors.glassBorder, width: 1),
              right: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.glassPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              // Body
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Themed dialog button — senior-friendly (min 52 dp height, font 16).
class GlassDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color color;
  final IconData? icon;
  final bool fullWidth;

  const GlassDialogButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = false,
    this.color = AppColors.brandPrimary,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 16, // ↑ senior-friendly
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (filled) {
      final button = FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // min ~52dp
          elevation: 0,
          minimumSize: Size(fullWidth ? double.infinity : 120, 52),
        ),
        child: content,
      );
      return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
    }

    // Outlined secondary (lebih kontras dari text-only)
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: Size(fullWidth ? double.infinity : 120, 52),
      ),
      child: content,
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Themed text field for use inside GlassDialog.
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int maxLines;
  final TextInputType? keyboardType;
  final Color accentColor;
  final bool obscureText;
  final Widget? suffixIcon;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.keyboardType,
    this.accentColor = AppColors.brandPrimary,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        labelStyle: TextStyle(color: accentColor, fontSize: 13),
        filled: true,
        fillColor: AppColors.glassPrimary,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}
