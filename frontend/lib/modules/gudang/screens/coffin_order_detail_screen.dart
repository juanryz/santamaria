import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class CoffinOrderDetailScreen extends StatefulWidget {
  final String coffinOrderId;
  const CoffinOrderDetailScreen({super.key, required this.coffinOrderId});

  @override
  State<CoffinOrderDetailScreen> createState() => _CoffinOrderDetailScreenState();
}

class _CoffinOrderDetailScreenState extends State<CoffinOrderDetailScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/coffin-orders/${widget.coffinOrderId}');
      if (res.data['success'] == true) {
        _order = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _completeStage(String stageId) async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Tahap'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Tukang')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Selesai')),
        ],
      ),
    );

    if (result == true) {
      try {
        await _api.dio.put('/gudang/coffin-orders/${widget.coffinOrderId}/stages/$stageId', data: {
          'completed_by_name': nameCtrl.text,
        });
        _loadData();
      } catch (_) {}
    }
  }

  Future<void> _submitQc() async {
    final qcResults = List<dynamic>.from(_order?['qc_results'] ?? []);
    final criteria = qcResults.isEmpty
        ? await _loadQcCriteria()
        : qcResults;

    if (criteria.isEmpty) return;
    if (!mounted) return;

    final results = <Map<String, dynamic>>[];
    for (final c in criteria) {
      results.add({
        'criteria_master_id': c['criteria_master_id'] ?? c['id'],
        'is_passed': c['is_passed'] ?? false,
      });
    }

    // Show QC dialog — capture context before await
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => _QcDialog(criteria: criteria),
    );

    if (confirmed != null) {
      try {
        await _api.dio.post('/gudang/coffin-orders/${widget.coffinOrderId}/qc', data: {'results': confirmed});
        _loadData();
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('QC submitted')));
      } catch (_) {}
    }
  }

  Future<List<dynamic>> _loadQcCriteria() async {
    try {
      final res = await _api.dio.get('/admin/master/coffin-qc-criteria');
      if (res.data['success'] == true) return List<dynamic>.from(res.data['data'] ?? []);
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _order?['coffin_order_number'] ?? 'Detail Peti',
        accentColor: AppColors.roleGudang,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.roleGudang,
          tabs: const [Tab(text: 'Tahap Pengerjaan'), Tab(text: 'QC')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : TabBarView(
                  controller: _tabController,
                  children: [_buildStagesTab(), _buildQcTab()],
                ),
    );
  }

  Widget _buildStagesTab() {
    final stages = List<dynamic>.from(_order?['stages'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        GlassWidget(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Kode: ${_order?['kode_peti'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    GlassStatusBadge(label: _order?['status'] ?? '', color: AppColors.roleGudang),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Finishing: ${_order?['finishing_type'] ?? '-'}'),
                if (_order?['warna'] != null) Text('Warna: ${_order!['warna']}'),
                if (_order?['ukuran'] != null) Text('Ukuran: ${_order!['ukuran']}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Stages timeline
        ...stages.map((s) {
          final completed = s['is_completed'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassWidget(
              borderRadius: 12,
              child: ListTile(
                leading: Icon(
                  completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: completed ? Colors.green : Colors.grey,
                ),
                title: Text('${s['stage_number']}. ${s['stage_name']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    )),
                subtitle: completed ? Text('Oleh: ${s['completed_by_name'] ?? '-'}') : null,
                trailing: completed ? null : IconButton(
                  icon: const Icon(Icons.check, color: AppColors.roleGudang),
                  onPressed: () => _completeStage(s['id']),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQcTab() {
    final results = List<dynamic>.from(_order?['qc_results'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada hasil QC')))
        else
          ...results.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassWidget(
                  borderRadius: 12,
                  child: ListTile(
                    leading: Icon(
                      r['is_passed'] == true ? Icons.check_circle : Icons.cancel,
                      color: r['is_passed'] == true ? Colors.green : Colors.red,
                    ),
                    title: Text(r['criteria_master']?['criteria_name'] ?? '-'),
                    subtitle: r['notes'] != null ? Text(r['notes']) : null,
                  ),
                ),
              )),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _submitQc,
          icon: const Icon(Icons.fact_check),
          label: const Text('Input QC'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.roleGudang, minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _QcDialog extends StatefulWidget {
  final List<dynamic> criteria;
  const _QcDialog({required this.criteria});

  @override
  State<_QcDialog> createState() => _QcDialogState();
}

class _QcDialogState extends State<_QcDialog> {
  late List<Map<String, dynamic>> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.criteria.map((c) => {
      'criteria_master_id': c['criteria_master_id'] ?? c['id'],
      'is_passed': c['is_passed'] ?? false,
      'name': c['criteria_master']?['criteria_name'] ?? c['criteria_name'] ?? '-',
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quality Control'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _results.length,
          itemBuilder: (_, i) {
            return SwitchListTile(
              title: Text(_results[i]['name']),
              value: _results[i]['is_passed'],
              activeThumbColor: Colors.green,
              onChanged: (v) => setState(() => _results[i]['is_passed'] = v),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final output = _results.map((r) => {
              'criteria_master_id': r['criteria_master_id'],
              'is_passed': r['is_passed'],
            }).toList();
            Navigator.pop(context, output);
          },
          child: const Text('Simpan QC'),
        ),
      ],
    );
  }
}
