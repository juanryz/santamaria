import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class KpiDashboardScreen extends StatefulWidget {
  const KpiDashboardScreen({super.key});

  @override
  State<KpiDashboardScreen> createState() => _KpiDashboardScreenState();
}

class _KpiDashboardScreenState extends State<KpiDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _kpiData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/my-kpi');
      if (res.data['success'] == true) {
        _kpiData = res.data['data'] != null ? Map<String, dynamic>.from(res.data['data']) : null;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      case 'E': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'KPI Saya', accentColor: AppColors.brandPrimary),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _kpiData == null
                ? const Center(child: Text('Belum ada periode KPI aktif'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildScoresList(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _kpiData?['summary'];
    final period = _kpiData?['period'];
    final grade = summary?['grade'] ?? '-';
    final score = summary?['total_score']?.toString() ?? '-';
    final trend = summary?['trend'] ?? 'stable';

    return GlassWidget(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(period?['period_name'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gradeColor(grade).withValues(alpha: 0.15),
                border: Border.all(color: _gradeColor(grade), width: 3),
              ),
              child: Center(
                child: Text(grade, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _gradeColor(grade))),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(score, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text(' / 100', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(width: 8),
                Icon(
                  trend == 'up' ? Icons.trending_up : trend == 'down' ? Icons.trending_down : Icons.trending_flat,
                  color: trend == 'up' ? Colors.green : trend == 'down' ? Colors.red : Colors.grey,
                ),
              ],
            ),
            if (summary?['rank_in_role'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Ranking: ${summary['rank_in_role']}/${summary['total_in_role']}',
                    style: const TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresList() {
    final scores = List<dynamic>.from(_kpiData?['scores'] ?? []);
    if (scores.isEmpty) return const Center(child: Text('Belum ada skor'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detail Metrik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...scores.map((s) {
          final score = (s['score'] as num?)?.toDouble() ?? 0;
          final metricName = s['metric']?['metric_name'] ?? '-';
          final unit = s['metric']?['unit'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassWidget(
              borderRadius: 14,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(metricName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        Text(score.toStringAsFixed(0), style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0, 1),
                        backgroundColor: Colors.grey.shade200,
                        color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Aktual: ${s['actual_value']} $unit | Target: ${s['target_value']} $unit',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
