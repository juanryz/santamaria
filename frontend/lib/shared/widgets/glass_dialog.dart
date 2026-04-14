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
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black38,
    builder: (ctx) => _GlassDialogWidget(
      title: title,
      content: content,
      actions: actions,
      accentColor: accentColor,
    ),
  );
}

/// Shortcut for simple confirm dialog.
Future<bool> showGlassConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  Color confirmColor = AppColors.brandPrimary,
  bool isDanger = false,
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    title: title,
    content: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    actions: [
      GlassDialogButton(
        label: cancelLabel,
        onPressed: () => Navigator.pop(context, false),
      ),
      GlassDialogButton(
        label: confirmLabel,
        filled: true,
        color: isDanger ? Colors.red : confirmColor,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
  );
  return result ?? false;
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

  const _GlassDialogWidget({
    required this.title,
    this.content,
    this.actions,
    this.accentColor = AppColors.brandPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xE6FFFFFF), // 90% white
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: accentColor.withValues(alpha: 0.10),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
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
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: content,
                    ),
                  ),
                // Actions
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!
                          .expand((a) => [a, const SizedBox(width: 8)])
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

/// Themed dialog button.
class GlassDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color color;
  final IconData? icon;

  const GlassDialogButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = false,
    this.color = AppColors.brandPrimary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)])
            : Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
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
