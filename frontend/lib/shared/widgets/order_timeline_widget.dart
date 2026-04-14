import 'package:flutter/material.dart';
import '../../core/services/config_service.dart';
import '../../core/constants/app_colors.dart';

/// Order status timeline — displays progress from pending to completed.
/// Labels and colors fetched from ConfigService (DB-driven, not hardcoded).
class OrderTimelineWidget extends StatelessWidget {
  final String currentStatus;
  final List<Map<String, dynamic>>? statusLogs;
  final bool showConsumerView;

  const OrderTimelineWidget({
    super.key,
    required this.currentStatus,
    this.statusLogs,
    this.showConsumerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final allStatuses = ConfigService.instance.getEnumItems('order_status');

    // Filter: consumer view only shows consumer-visible statuses
    final visibleStatuses = showConsumerView
        ? allStatuses.where((s) => s['show_to_consumer'] == true).toList()
        : allStatuses;

    if (visibleStatuses.isEmpty) {
      // Fallback if config not loaded
      return _buildFallbackTimeline();
    }

    final currentIndex = visibleStatuses.indexWhere((s) => s['value'] == currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(visibleStatuses.length, (i) {
        final status = visibleStatuses[i];
        final statusCode = status['value'] as String;
        final label = (showConsumerView ? status['consumer_label'] : status['internal_label']) ?? statusCode;
        final colorHex = status['color'] as String? ?? '#9E9E9E';
        final color = _parseColor(colorHex);

        final isCompleted = currentIndex >= 0 && i < currentIndex;
        final isCurrent = i == currentIndex;
        final isFuture = currentIndex >= 0 && i > currentIndex;
        final isCancelled = currentStatus == 'cancelled';

        // Find log entry for this status
        final logEntry = statusLogs?.where((l) => l['to_status'] == statusCode).toList();
        final timestamp = logEntry?.isNotEmpty == true ? logEntry!.last['created_at'] : null;

        return _buildTimelineItem(
          label: label,
          description: showConsumerView ? (status['consumer_description'] as String?) : null,
          color: isCancelled && isCurrent ? Colors.red : color,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isFuture: isFuture,
          isLast: i == visibleStatuses.length - 1,
          timestamp: timestamp,
          showMapIcon: status['show_map_tracking'] == true && isCurrent,
        );
      }),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    String? description,
    required Color color,
    required bool isCompleted,
    required bool isCurrent,
    required bool isFuture,
    required bool isLast,
    String? timestamp,
    bool showMapIcon = false,
  }) {
    final dotColor = isCompleted
        ? Colors.green
        : isCurrent
            ? color
            : Colors.grey.shade300;

    final lineColor = isCompleted ? Colors.green.shade200 : Colors.grey.shade200;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dots & line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 16 : 12,
                  height: isCurrent ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent ? Border.all(color: color, width: 3) : null,
                    boxShadow: isCurrent
                        ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)]
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isFuture ? Colors.grey.shade400 : AppColors.brandPrimary,
                            fontSize: isCurrent ? 14 : 13,
                          ),
                        ),
                      ),
                      if (showMapIcon)
                        Icon(Icons.map, size: 16, color: color),
                    ],
                  ),
                  if (description != null && (isCompleted || isCurrent))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTimeline() {
    final steps = ['Pending', 'Dikonfirmasi', 'Persiapan', 'Berlangsung', 'Selesai'];
    final currentIdx = ['pending', 'confirmed', 'preparing', 'in_progress', 'completed']
        .indexOf(currentStatus)
        .clamp(0, steps.length - 1);

    return Column(
      children: List.generate(steps.length, (i) => _buildTimelineItem(
        label: steps[i],
        color: AppColors.brandPrimary,
        isCompleted: i < currentIdx,
        isCurrent: i == currentIdx,
        isFuture: i > currentIdx,
        isLast: i == steps.length - 1,
      )),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}
