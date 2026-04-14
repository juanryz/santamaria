import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class HrdViolationDetailScreen extends StatefulWidget {
  final String violationId;
  const HrdViolationDetailScreen({super.key, required this.violationId});

  @override
  State<HrdViolationDetailScreen> createState() => _HrdViolationDetailScreenState();
}

class _HrdViolationDetailScreenState extends State<HrdViolationDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _violation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/violations/${widget.violationId}');
      if (res.data['success'] == true) {
        _violation = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acknowledge() async {
    try {
      await _api.dio.put('/hrd/violations/${widget.violationId}/acknowledge');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggaran diakui')));
    } catch (_) {}
  }

  Future<void> _resolve() async {
    final notes = await _showNotesDialog('Catatan Penyelesaian');
    if (notes == null) return;
    try {
      await _api.dio.put('/hrd/violations/${widget.violationId}/resolve', data: {'notes': notes});
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggaran diselesaikan')));
    } catch (_) {}
  }

  Future<void> _escalate() async {
    final notes = await _showNotesDialog('Catatan Eskalasi');
    if (notes == null) return;
    try {
      await _api.dio.put('/hrd/violations/${widget.violationId}/escalate', data: {'notes': notes});
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggaran dieskalasi')));
    } catch (_) {}
  }

  Future<String?> _showNotesDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Masukkan catatan...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Detail Pelanggaran', accentColor: AppColors.roleHrd),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _violation == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassWidget(
                      borderRadius: 16,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (_violation!['violation_type'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GlassStatusBadge(label: _violation!['status'] ?? '', color: AppColors.roleHrd),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _infoRow('Karyawan', _violation!['user']?['name'] ?? '-'),
                            _infoRow('Role', _violation!['user']?['role'] ?? '-'),
                            _infoRow('Deskripsi', _violation!['description'] ?? '-'),
                            _infoRow('Tanggal', _violation!['created_at'] ?? '-'),
                            if (_violation!['notes'] != null) _infoRow('Catatan', _violation!['notes']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_violation!['status'] == 'pending') ...[
                      FilledButton.icon(
                        onPressed: _acknowledge,
                        icon: const Icon(Icons.check),
                        label: const Text('Akui Pelanggaran'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size.fromHeight(48)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_violation!['status'] != 'resolved' && _violation!['status'] != 'escalated') ...[
                      FilledButton.icon(
                        onPressed: _resolve,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Selesaikan'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(48)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _escalate,
                        icon: const Icon(Icons.arrow_upward, color: Colors.red),
                        label: const Text('Eskalasi ke Owner', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
