import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Owner — list anomali purchase order (read-only).
class OwnerAnomalyListScreen extends StatefulWidget {
  const OwnerAnomalyListScreen({super.key});

  @override
  State<OwnerAnomalyListScreen> createState() => _OwnerAnomalyListScreenState();
}

class _OwnerAnomalyListScreenState extends State<OwnerAnomalyListScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/owner/purchase-orders/anomalies');
      if (res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        if (d is List) _items = List<dynamic>.from(d);
      }
    } catch (e) {
      debugPrint('Owner anomaly list error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Anomali',
        accentColor: AppColors.statusDanger,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildItem(_items[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 72, color: AppColors.statusSuccess),
              SizedBox(height: 16),
              Text(
                'Tidak ada anomali',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Semua berjalan normal',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(dynamic a) {
    final title = (a['title']?.toString()) ?? 'Anomali Terdeteksi';
    final description = (a['description']?.toString()) ?? '-';
    final severity = (a['severity']?.toString()) ?? 'medium';
    final severityColor = switch (severity) {
      'high' || 'critical' => AppColors.statusDanger,
      'medium' => AppColors.statusWarning,
      _ => AppColors.statusInfo,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: severityColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
