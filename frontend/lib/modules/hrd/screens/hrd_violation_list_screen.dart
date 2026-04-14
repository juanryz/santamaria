import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import 'hrd_violation_detail_screen.dart';

class HrdViolationListScreen extends StatefulWidget {
  const HrdViolationListScreen({super.key});

  @override
  State<HrdViolationListScreen> createState() => _HrdViolationListScreenState();
}

class _HrdViolationListScreenState extends State<HrdViolationListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _violations = [];
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterStatus != null) params['status'] = _filterStatus;
      final res = await _api.dio.get('/hrd/violations', queryParameters: params);
      if (res.data['success'] == true) {
        _violations = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Pelanggaran', accentColor: AppColors.roleHrd),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _violations.isEmpty
                      ? const Center(child: Text('Tidak ada pelanggaran'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _violations.length,
                          itemBuilder: (_, i) => _buildViolationCard(_violations[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [null, 'pending', 'acknowledged', 'resolved', 'escalated'];
    final labels = ['Semua', 'Pending', 'Diakui', 'Selesai', 'Eskalasi'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(filters.length, (i) {
          final isSelected = _filterStatus == filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: isSelected,
              selectedColor: AppColors.roleHrd.withValues(alpha: 0.2),
              onSelected: (_) {
                setState(() => _filterStatus = filters[i]);
                _loadData();
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildViolationCard(dynamic v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(
            _getViolationIcon(v['violation_type'] ?? ''),
            color: _getSeverityColor(v['severity'] ?? ''),
            size: 32,
          ),
          title: Text(
            v['violation_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(v['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              GlassStatusBadge(
                label: v['status'] ?? 'pending',
                color: _getStatusColor(v['status'] ?? ''),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HrdViolationDetailScreen(violationId: v['id'])),
          ),
        ),
      ),
    );
  }

  IconData _getViolationIcon(String type) {
    if (type.contains('overtime')) return Icons.timer_off;
    if (type.contains('late')) return Icons.schedule;
    if (type.contains('attendance')) return Icons.person_off;
    if (type.contains('equipment')) return Icons.build;
    if (type.contains('coffin')) return Icons.inventory;
    return Icons.warning_amber;
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'acknowledged': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'escalated': return Colors.red;
      default: return Colors.grey;
    }
  }
}
