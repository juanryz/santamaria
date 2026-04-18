import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.39 — HRD approval untuk cuti/sakit/izin karyawan.
class LeavesApprovalScreen extends StatefulWidget {
  const LeavesApprovalScreen({super.key});

  @override
  State<LeavesApprovalScreen> createState() => _LeavesApprovalScreenState();
}

class _LeavesApprovalScreenState extends State<LeavesApprovalScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _leaves = [];
  String _filter = 'requested';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/hrd/leaves', queryParameters: {
        if (_filter != 'all') 'status': _filter,
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        final d = res.data['data'];
        setState(() => _leaves =
            List<dynamic>.from(d is Map ? (d['data'] ?? []) : d));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat daftar cuti.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> leave) async {
    final user = leave['user'] as Map<String, dynamic>?;
    final ok = await ConfirmDialog.show(
      context,
      title: 'Setujui Request?',
      message: '${user?['name']} — ${leave['leave_type']} ${leave['days_count']} hari',
      confirmLabel: 'Setujui',
      confirmColor: AppColors.statusSuccess,
    );
    if (!ok) return;

    try {
      final res = await _api.dio.put('/hrd/leaves/${leave['id']}/approve');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Disetujui'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyetujui'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> leave) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Jelaskan alasan...',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    try {
      final res = await _api.dio
          .put('/hrd/leaves/${leave['id']}/reject', data: {'reason': reason});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Ditolak'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menolak'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Cuti & Izin',
        accentColor: AppColors.roleHrd,
        showBack: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Menunggu', 'requested'),
                _chip('Disetujui', 'approved'),
                _chip('Ditolak', 'rejected'),
                _chip('Semua', 'all'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _leaves.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppColors.roleHrd.withOpacity(0.15),
        labelStyle: TextStyle(
            color: selected ? AppColors.roleHrd : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.event_busy_outlined,
        title: 'Tidak Ada Request',
        subtitle: 'Request cuti/izin karyawan akan muncul di sini.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaves.length,
        itemBuilder: (c, i) => _card(_leaves[i] as Map<String, dynamic>),
      );

  Widget _card(Map<String, dynamic> l) {
    final user = l['user'] as Map<String, dynamic>?;
    final status = (l['status'] ?? '').toString();
    final type = (l['leave_type'] ?? '').toString();
    final start = DateTime.tryParse(l['start_date'] ?? '');
    final end = DateTime.tryParse(l['end_date'] ?? '');
    final days = l['days_count'] ?? 0;
    final isPending = status == 'requested';

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.roleHrd.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                        '${_typeLabel(type)} · ${(user?['role'] ?? '').toString().replaceAll('_', ' ')}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                  start != null && end != null
                      ? '${DateFormat('d MMM', 'id_ID').format(start)} – ${DateFormat('d MMM yyyy', 'id_ID').format(end)}  ($days hari)'
                      : '-',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          if ((l['reason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Alasan: ${l['reason']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],
          if ((l['rejection_reason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Alasan penolakan: ${l['rejection_reason']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.statusDanger,
                    fontStyle: FontStyle.italic)),
          ],
          if (isPending) ...[
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(l),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(color: AppColors.statusDanger)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approve(l),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Setujui'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'cuti_tahunan' => 'Cuti Tahunan',
        'sakit' => 'Sakit',
        'izin' => 'Izin',
        'thr' => 'THR',
        'cuti_khusus' => 'Cuti Khusus',
        _ => t,
      };

  Widget _statusBadge(String s) {
    final (label, color) = switch (s) {
      'approved' => ('Disetujui', AppColors.statusSuccess),
      'rejected' => ('Ditolak', AppColors.statusDanger),
      'requested' => ('Menunggu', AppColors.statusWarning),
      'cancelled' => ('Cancelled', AppColors.textHint),
      _ => (s, AppColors.textHint),
    };
    return GlassStatusBadge(label: label, color: color);
  }

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
                  onPressed: _load, child: const Text('Coba Lagi'))),
        ],
      );
}
