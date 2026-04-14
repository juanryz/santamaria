import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class KpiManagementScreen extends StatefulWidget {
  const KpiManagementScreen({super.key});

  @override
  State<KpiManagementScreen> createState() => _KpiManagementScreenState();
}

class _KpiManagementScreenState extends State<KpiManagementScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  late TabController _tabController;

  Map<String, List<dynamic>> _metricsByRole = {};
  List<dynamic> _periods = [];
  Map<String, List<dynamic>> _rankings = {};
  String? _selectedPeriodId;

  final _roles = ['service_officer', 'gudang', 'purchasing', 'driver'];
  final _roleLabels = {'service_officer': 'SO', 'gudang': 'Gudang', 'purchasing': 'Purchasing', 'driver': 'Driver'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final metricsRes = await _api.dio.get('/hrd/kpi/metrics');
      if (metricsRes.data['success'] == true) {
        final allMetrics = List<dynamic>.from(metricsRes.data['data'] ?? []);
        _metricsByRole = {};
        for (final m in allMetrics) {
          final role = m['applicable_role'] ?? 'other';
          _metricsByRole.putIfAbsent(role, () => []).add(m);
        }
      }

      final periodsRes = await _api.dio.get('/hrd/kpi/periods');
      if (periodsRes.data['success'] == true) {
        _periods = List<dynamic>.from(periodsRes.data['data'] ?? []);
        if (_periods.isNotEmpty) {
          _selectedPeriodId = _periods.first['id'];
          await _loadRankings();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRankings() async {
    if (_selectedPeriodId == null) return;
    try {
      final res = await _api.dio.get('/hrd/kpi/periods/$_selectedPeriodId/rankings');
      if (res.data['success'] == true) {
        _rankings = {};
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        data.forEach((key, value) {
          _rankings[key] = List<dynamic>.from(value);
        });
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Manajemen KPI',
        accentColor: AppColors.roleHrd,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.roleHrd,
          tabs: const [Tab(text: 'Metrik'), Tab(text: 'Ranking'), Tab(text: 'Periode')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildMetricsTab(), _buildRankingsTab(), _buildPeriodsTab()],
            ),
    );
  }

  Widget _buildMetricsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _roles.map((role) {
        final metrics = _metricsByRole[role] ?? [];
        if (metrics.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_roleLabels[role] ?? role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...metrics.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassWidget(
                    borderRadius: 12,
                    child: ListTile(
                      dense: true,
                      title: Text(m['metric_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Target: ${m['target_value']} ${m['unit']} | Bobot: ${m['weight']}%', style: const TextStyle(fontSize: 11)),
                      trailing: Icon(
                        m['target_direction'] == 'lower_is_better' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: AppColors.roleHrd,
                        size: 18,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRankingsTab() {
    if (_periods.isEmpty) return const Center(child: Text('Belum ada periode'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButton<String>(
          value: _selectedPeriodId,
          isExpanded: true,
          items: _periods.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['period_name'] ?? ''))).toList(),
          onChanged: (v) {
            _selectedPeriodId = v;
            _loadRankings();
          },
        ),
        const SizedBox(height: 16),
        ..._rankings.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...entry.value.asMap().entries.map((e) {
                final s = e.value;
                final grade = s['grade'] ?? '-';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassWidget(
                    borderRadius: 12,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _gradeColor(grade).withValues(alpha: 0.15),
                        child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: _gradeColor(grade))),
                      ),
                      title: Text(s['user']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Skor: ${s['total_score']}', style: const TextStyle(fontSize: 12)),
                      trailing: Text('#${e.key + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPeriodsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _periods.length,
      itemBuilder: (_, i) {
        final p = _periods[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassWidget(
            borderRadius: 14,
            child: ListTile(
              title: Text(p['period_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p['start_date']} — ${p['end_date']}', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: p['status'] == 'open' ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p['status'] ?? '', style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p['status'] == 'open' ? Colors.green : Colors.grey,
                )),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
