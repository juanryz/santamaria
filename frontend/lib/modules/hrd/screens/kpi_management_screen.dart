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

  String? _filterRole;
  final _roles = ['service_officer', 'gudang', 'purchasing', 'driver', 'dekor', 'konsumsi', 'pemuka_agama', 'tukang_foto', 'hrd', 'security'];
  final _roleLabels = {
    'service_officer': 'SO', 'gudang': 'Gudang', 'purchasing': 'Purchasing',
    'driver': 'Driver', 'dekor': 'Dekor', 'konsumsi': 'Konsumsi',
    'pemuka_agama': 'Pemuka Agama', 'tukang_foto': 'Tukang Foto',
    'hrd': 'HRD', 'security': 'Security',
  };

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
                      subtitle: Text('Target: ${m['target_value']} ${m['unit']} | Bobot: ${m['weight']}%', style: const TextStyle(fontSize: 13)),
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

  void _showKpiDetail(Map<String, dynamic> summary) async {
    final userId = summary['user']?['id'] ?? summary['user_id'];
    if (userId == null) return;
    List<dynamic> details = [];
    try {
      final res = await _api.dio.get('/hrd/kpi/scores/user/$userId', queryParameters: {
        if (_selectedPeriodId != null) 'period_id': _selectedPeriodId,
      });
      if (res.data['success'] == true) {
        details = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (!mounted) return;
    final grade = summary['grade'] ?? '-';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _gradeColor(grade).withValues(alpha: 0.15),
                  child: Text(grade, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _gradeColor(grade))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(summary['user']?['name'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${summary['user']?['role'] ?? '-'} — Skor: ${summary['total_score'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ])),
              ]),
              const Divider(height: 32),
              if (details.isEmpty)
                const Text('Tidak ada detail metrik', style: TextStyle(color: Colors.grey))
              else
                ...details.map((d) {
                  final score = (d['score'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassWidget(
                      borderRadius: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['metric_name'] ?? d['metric']?['metric_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _metricChip('Target', '${d['target_value']}'),
                            const SizedBox(width: 8),
                            _metricChip('Aktual', '${d['actual_value']}'),
                            const SizedBox(width: 8),
                            _metricChip('Skor', '${d['score']}', color: score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.red),
                            const SizedBox(width: 8),
                            _metricChip('Bobot', '${d['weight']}%'),
                          ]),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (score / 100).clamp(0, 1),
                            backgroundColor: Colors.grey.shade200,
                            color: score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.red,
                            minHeight: 4,
                          ),
                        ]),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildRankingsTab() {
    if (_periods.isEmpty) return const Center(child: Text('Belum ada periode'));

    final roleOptions = <String?>[null, ..._roles];
    final filteredRankings = _filterRole == null
        ? _rankings
        : Map.fromEntries(_rankings.entries.where((e) => e.key.toLowerCase().contains(_filterRole!)));

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
        const SizedBox(height: 8),
        DropdownButton<String?>(
          value: _filterRole,
          isExpanded: true,
          hint: const Text('Filter: Semua Role'),
          items: roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r == null ? 'Semua Role' : (_roleLabels[r] ?? r)))).toList(),
          onChanged: (v) => setState(() => _filterRole = v),
        ),
        const SizedBox(height: 16),
        ...filteredRankings.entries.map((entry) {
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
                    onTap: () => _showKpiDetail(s),
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
