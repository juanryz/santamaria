import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_widget.dart';
import '../widgets/glass_status_badge.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirm_dialog.dart';

/// v1.39 — Karyawan self-service cuti/sakit/izin.
/// Dipakai semua role internal (SO, Gudang, Purchasing, Driver, dll).
class MyLeavesScreen extends StatefulWidget {
  const MyLeavesScreen({super.key});

  @override
  State<MyLeavesScreen> createState() => _MyLeavesScreenState();
}

class _MyLeavesScreenState extends State<MyLeavesScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _leaves = [];

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
      final res = await _api.dio.get('/me/leaves');
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
      setState(() => _error = 'Gagal memuat riwayat cuti.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestLeave() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _RequestForm()),
    );
    if (result == true) _load();
  }

  Future<void> _cancel(Map<String, dynamic> l) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Batalkan Request?',
      message: 'Request ${l['leave_type']} akan dibatalkan.',
      confirmLabel: 'Batalkan',
    );
    if (!ok) return;

    try {
      final res = await _api.dio.put('/me/leaves/${l['id']}/cancel');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Dibatalkan'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal membatalkan'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Cuti & Izin Saya',
        accentColor: AppColors.brandPrimary,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: _requestLeave,
        icon: const Icon(Icons.event_note, color: Colors.white),
        label: const Text('Request Cuti',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _leaves.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.event_available_outlined,
        title: 'Belum Ada Request',
        subtitle: 'Tekan tombol "Request Cuti" untuk mengajukan cuti/sakit/izin.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _leaves.length,
        itemBuilder: (c, i) => _card(_leaves[i] as Map<String, dynamic>),
      );

  Widget _card(Map<String, dynamic> l) {
    final status = (l['status'] ?? '').toString();
    final type = (l['leave_type'] ?? '').toString();
    final start = DateTime.tryParse(l['start_date'] ?? '');
    final end = DateTime.tryParse(l['end_date'] ?? '');
    final approver = l['approver'] as Map<String, dynamic>?;
    final days = l['days_count'] ?? 0;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.brandPrimary.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_typeLabel(type),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
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
                      fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
          if ((l['reason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(l['reason'],
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (status == 'approved' && approver != null) ...[
            const SizedBox(height: 6),
            Text('Disetujui oleh ${approver['name']}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.statusSuccess)),
          ],
          if (status == 'rejected' &&
              (l['rejection_reason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Ditolak: ${l['rejection_reason']}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.statusDanger)),
          ],
          if (status == 'requested') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancel(l),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Batalkan'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusDanger),
              ),
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
      'cancelled' => ('Dibatalkan', AppColors.textHint),
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

// ─────────────────────────────────────────────────────────────
// Request form
// ─────────────────────────────────────────────────────────────

class _RequestForm extends StatefulWidget {
  const _RequestForm();

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  String _type = 'cuti_tahunan';
  DateTime? _start;
  DateTime? _end;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _days {
    if (_start == null || _end == null) return 0;
    return _end!.difference(_start!).inDays + 1;
  }

  Future<void> _save() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih tanggal mulai & akhir'),
            backgroundColor: AppColors.statusWarning),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal akhir harus setelah tanggal mulai'),
            backgroundColor: AppColors.statusDanger),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.dio.post('/me/leaves', data: {
        'leave_type': _type,
        'start_date': DateFormat('yyyy-MM-dd').format(_start!),
        'end_date': DateFormat('yyyy-MM-dd').format(_end!),
        'reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Request terkirim. Menunggu approval HRD.'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal mengirim'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal mengirim request'),
            backgroundColor: AppColors.statusDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Request Cuti/Izin',
        accentColor: AppColors.brandPrimary,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Jenis',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'cuti_tahunan', child: Text('Cuti Tahunan')),
                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                DropdownMenuItem(value: 'cuti_khusus', child: Text('Cuti Khusus')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'cuti_tahunan'),
            ),
            const SizedBox(height: 14),

            const Text('Tanggal Mulai',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _start = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.date_range),
                  filled: true,
                  fillColor: AppColors.backgroundSoft,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                child: Text(_start == null
                    ? 'Pilih tanggal'
                    : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_start!)),
              ),
            ),
            const SizedBox(height: 10),

            const Text('Tanggal Akhir',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _end ?? _start ?? DateTime.now(),
                  firstDate: _start ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _end = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.event_available),
                  filled: true,
                  fillColor: AppColors.backgroundSoft,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                child: Text(_end == null
                    ? 'Pilih tanggal'
                    : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_end!)),
              ),
            ),
            const SizedBox(height: 10),

            if (_days > 0)
              GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusInfo.withOpacity(0.1),
                borderColor: AppColors.statusInfo.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.statusInfo),
                    const SizedBox(width: 8),
                    Text('Durasi: $_days hari',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusInfo)),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            const Text('Alasan',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan cuti/izin...',
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              validator: (v) {
                if (_type == 'sakit' && _days > 1 && (v ?? '').trim().isEmpty) {
                  return 'Wajib diisi untuk sakit > 1 hari';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Mengirim…' : 'Kirim Request'),
            ),
          ],
        ),
      ),
    );
  }
}
