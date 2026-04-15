import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_widget.dart';

class RoleFulfillmentScreen extends StatefulWidget {
  final String orderId;

  const RoleFulfillmentScreen({super.key, required this.orderId});

  @override
  State<RoleFulfillmentScreen> createState() => _RoleFulfillmentScreenState();
}

class _RoleFulfillmentScreenState extends State<RoleFulfillmentScreen> {
  final _api = ApiClient();
  List<dynamic> _items = [];
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  final Map<String, bool> _toggling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio
          .get('/role-stock/orders/${widget.orderId}/checklist');
      if (res.data['success'] == true && mounted) {
        final data = List<dynamic>.from(res.data['data'] ?? []);
        setState(() {
          _items = data;
          if (data.isNotEmpty) {
            _order = data.first['order'] as Map<String, dynamic>?;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat checklist.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final isChecked = item['is_checked'] as bool? ?? false;
    if (_toggling[id] == true) return;

    setState(() => _toggling[id] = true);
    try {
      final endpoint = isChecked
          ? '/role-stock/checklist/$id/uncheck'
          : '/role-stock/checklist/$id/check';
      await _api.dio.put(endpoint);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status item.')),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount =
        _items.where((i) => i['is_checked'] == true).length;
    final total = _items.length;
    final progress = total > 0 ? checkedCount / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Checklist Pemenuhan',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // Order info + progress bar header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: GlassWidget(
                        borderRadius: 20,
                        blurSigma: 16,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_order != null) ...[
                              Text(
                                _order!['order_number'] ?? '-',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _order!['deceased_name'] ?? '',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                              if (_order!['scheduled_at'] != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 13,
                                        color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      _order!['scheduled_at']
                                          .toString()
                                          .substring(0, 16),
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$checkedCount / $total item selesai',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: progress == 1.0
                                        ? AppColors.statusSuccess
                                        : AppColors.roleGudang,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.glassBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0
                                      ? AppColors.statusSuccess
                                      : AppColors.roleGudang,
                                ),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Checklist items
                  if (_items.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: AppColors.textHint),
                            SizedBox(height: 16),
                            Text('Tidak ada item untuk order ini.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildChecklistItem(
                              _items[i] as Map<String, dynamic>),
                          childCount: _items.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item) {
    final isChecked = item['is_checked'] as bool? ?? false;
    final id = item['id'] as String;
    final isToggling = _toggling[id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: isChecked
            ? AppColors.statusSuccess.withValues(alpha: 0.06)
            : AppColors.glassWhite,
        borderColor: isChecked
            ? AppColors.statusSuccess.withValues(alpha: 0.3)
            : AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            isToggling
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.roleGudang),
                  )
                : GestureDetector(
                    onTap: () => _toggle(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? AppColors.statusSuccess
                            : Colors.transparent,
                        border: Border.all(
                          color: isChecked
                              ? AppColors.statusSuccess
                              : AppColors.glassBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '-',
                    style: TextStyle(
                      color: isChecked
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item['quantity'] ?? 1} ${item['unit'] ?? 'pcs'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (isChecked && item['checked_at'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Selesai: ${item['checked_at'].toString().substring(0, 16)}',
                      style: const TextStyle(
                          color: AppColors.statusSuccess, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
