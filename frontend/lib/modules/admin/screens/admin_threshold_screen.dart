import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminThresholdScreen extends StatefulWidget {
  const AdminThresholdScreen({super.key});

  @override
  State<AdminThresholdScreen> createState() => _AdminThresholdScreenState();
}

class _AdminThresholdScreenState extends State<AdminThresholdScreen> {
  static const _accent = AppColors.roleAdmin;
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/config/thresholds');
      final data = res.data is Map && res.data['data'] != null
          ? res.data['data']
          : res.data;
      _items = List<Map<String, dynamic>>.from(data is List ? data : []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _categoryOf(Map<String, dynamic> item) {
    final key = (item['key'] ?? '') as String;
    if (key.startsWith('driver_') || key.startsWith('fuel_') || key.startsWith('km_')) return 'Kendaraan & Driver';
    if (key.startsWith('kpi_')) return 'KPI';
    if (key.startsWith('attendance_') || key.startsWith('daily_attendance_') || key.startsWith('mock_')) return 'Presensi';
    if (key.startsWith('purchasing_') || key.startsWith('supplier_') || key.startsWith('payment_')) return 'Purchasing & Payment';
    if (key.startsWith('so_')) return 'Service Officer';
    if (key.startsWith('vendor_')) return 'Vendor';
    if (key.startsWith('equipment_') || key.startsWith('coffin_') || key.startsWith('death_cert_')) return 'Peralatan & Dokumen';
    if (key.startsWith('consumer_')) return 'Consumer';
    if (key.startsWith('order_') || key.startsWith('amendment_')) return 'Order';
    if (key.startsWith('maintenance_') || key.startsWith('inspection_')) return 'Maintenance';
    return 'Lainnya';
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final controller = TextEditingController(text: '${item['value'] ?? ''}');
    final key = item['key'] ?? '';
    final unit = item['unit'] ?? '';
    final desc = item['description'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: GlassWidget(
            borderRadius: 24,
            blurSigma: 20,
            tint: AppColors.glassWhite,
            borderColor: _accent.withValues(alpha: 0.2),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Nilai',
                    suffixText: unit,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final val = num.tryParse(controller.text.trim());
                        await _api.dio.put('/hrd/thresholds/$key', data: {'value': val ?? controller.text.trim()});
                        _fetch();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Threshold Sistem',
        accentColor: _accent,
        actions: [
          GlassIconButton(
            icon: Icons.refresh,
            onPressed: _fetch,
            color: _accent,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.statusDanger, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildGroupedList(),
    );
  }

  Widget _buildGroupedList() {
    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _items) {
      final cat = _categoryOf(item);
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return RefreshIndicator(
      color: _accent,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final category in sortedKeys) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                category,
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            for (final item in grouped[category]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassWidget(
                  borderRadius: 14,
                  blurSigma: 12,
                  tint: AppColors.glassWhite,
                  borderColor: AppColors.glassBorder,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  onTap: () => _showEditDialog(item),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['key'] ?? ''}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if ((item['description'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${item['description']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item['value'] ?? '-'} ${item['unit'] ?? ''}',
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined,
                          color: AppColors.textHint, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
