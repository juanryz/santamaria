import 'package:flutter/material.dart';
import '../../core/services/config_service.dart';
import 'glass_status_badge.dart';

/// Status badge that resolves labels from ConfigService — NO hardcoded status labels.
/// Usage: DynamicStatusBadge(enumGroup: 'order_status', value: 'confirmed')
/// This will display "Dikonfirmasi" (from backend config) instead of "confirmed".
class DynamicStatusBadge extends StatelessWidget {
  final String enumGroup; // 'order_status', 'payment_status', 'coffin_status', etc.
  final String value;     // The raw enum value, e.g. 'confirmed', 'paid', etc.
  final Color? color;     // Override color (optional)

  const DynamicStatusBadge({
    super.key,
    required this.enumGroup,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final label = ConfigService.instance.getLabel(enumGroup, value);
    final resolvedColor = color ?? _autoColor(value);

    return GlassStatusBadge(label: label, color: resolvedColor);
  }

  /// Auto-determine color based on common status patterns.
  /// Falls back to grey if unknown.
  Color _autoColor(String status) {
    // Positive
    if (_isPositive(status)) return const Color(0xFF4CAF50);
    // Warning / in-progress
    if (_isWarning(status)) return const Color(0xFFFF9800);
    // Negative
    if (_isNegative(status)) return const Color(0xFFF44336);
    // Info / pending
    if (_isInfo(status)) return const Color(0xFF2196F3);
    // Default grey
    return const Color(0xFF9E9E9E);
  }

  bool _isPositive(String s) =>
      s.contains('completed') || s.contains('passed') || s.contains('paid') ||
      s.contains('verified') || s.contains('present') || s.contains('returned') ||
      s.contains('received') || s.contains('approved') || s.contains('resolved');

  bool _isWarning(String s) =>
      s.contains('progress') || s.contains('process') || s.contains('evaluating') ||
      s.contains('late') || s.contains('partial') || s.contains('uploaded') ||
      s.contains('calculating') || s.contains('shipping');

  bool _isNegative(String s) =>
      s.contains('cancelled') || s.contains('failed') || s.contains('rejected') ||
      s.contains('absent') || s.contains('missing') || s.contains('overdue');

  bool _isInfo(String s) =>
      s.contains('pending') || s.contains('draft') || s.contains('scheduled') ||
      s.contains('open') || s.contains('prepared') || s.contains('sent');
}
