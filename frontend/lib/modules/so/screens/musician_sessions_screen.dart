import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.40 — Sesi Musisi per Order.
///
/// Aturan:
/// - Bayaran per orang per sesi (bukan per grup per order)
/// - Rate diambil dari musician_wage_config aktif
/// - 1 grup 5 orang × 2 sesi = 10 × rate_per_person
class MusicianSessionsScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const MusicianSessionsScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<MusicianSessionsScreen> createState() => _MusicianSessionsScreenState();
}

class _MusicianSessionsScreenState extends State<MusicianSessionsScreen> {
  final _api = ApiClient();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _loading = true;
  String? _error;

  List<dynamic> _sessions = [];
  List<dynamic> _wageConfigs = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.dio.get('/admin/orders/${widget.orderId}/musician-sessions'),
        _api.dio.get('/admin/musicians/wage-configs'),
      ]);
      if (!mounted) return;
      setState(() {
        final sData = results[0].data['data'];
        final wData = results[1].data['data'];
        _sessions = sData is List ? sData : [];
        _wageConfigs = wData is List ? wData : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data.';
        _loading = false;
      });
    }
  }

  double _totalWage() => _sessions.fold<double>(
        0,
        (sum, s) => sum + (double.tryParse('${s['total_wage']}') ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Sesi Musisi — ${widget.orderNumber}',
        accentColor: AppColors.roleSO,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildSummary(),
                      const SizedBox(height: 16),
                      _buildRatesInfo(),
                      const SizedBox(height: 16),
                      _buildSessionsHeader(),
                      const SizedBox(height: 8),
                      if (_sessions.isEmpty)
                        _buildEmptySessions()
                      else
                        ..._sessions.map((s) => _buildSessionCard(s)),
                    ],
                  ),
      ),
      floatingActionButton: _wageConfigs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateDialog,
              backgroundColor: AppColors.roleSO,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Sesi', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildSummary() {
    final total = _totalWage();
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.roleSO.withValues(alpha: 0.06),
      borderColor: AppColors.roleSO.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.roleSO.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note, color: AppColors.roleSO, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currency.format(total),
                  style: const TextStyle(
                    color: AppColors.roleSO,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_sessions.length} sesi — total upah musisi',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesInfo() {
    if (_wageConfigs.isEmpty) {
      return GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.statusWarning.withValues(alpha: 0.08),
        borderColor: AppColors.statusWarning.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(14),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.statusWarning),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada tarif musisi dikonfigurasi. Hubungi Admin untuk set rate.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return GlassWidget(
      borderRadius: 14,
      blurSigma: 10,
      tint: AppColors.glassWhite,
      borderColor: AppColors.textHint.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarif Per Orang Per Sesi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._wageConfigs.map((c) {
            final rate = double.tryParse('${c['rate_per_session_per_person']}') ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(_iconForRole(c['role_label']), size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _labelForRole(c['role_label']),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  Text(
                    _currency.format(rate),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionsHeader() {
    return Row(
      children: [
        const Text(
          'Daftar Sesi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          '${_sessions.length} sesi',
          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptySessions() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.music_off, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Belum ada sesi musisi.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan sesi via tombol + di bawah.',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(dynamic s) {
    final sessionType = s['session_type'] as String? ?? '-';
    final sessionDate = s['session_date'] as String? ?? '';
    final count = s['musician_count'] as int? ?? 0;
    final rate = double.tryParse('${s['rate_per_person']}') ?? 0;
    final total = double.tryParse('${s['total_wage']}') ?? 0;
    final location = s['location'] as String?;
    final start = s['session_start_time'] as String?;
    final end = s['session_end_time'] as String?;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: AppColors.roleSO.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.roleSO.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _labelForSessionType(sessionType),
                    style: const TextStyle(
                      color: AppColors.roleSO,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusDanger),
                  onPressed: () => _confirmDelete(s),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(sessionDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (start != null && end != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$start – $end',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ],
            ),
            if (location != null && location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(location,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count orang × ${_currency.format(rate)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(
                        _currency.format(total),
                        style: const TextStyle(
                          color: AppColors.roleSO,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateSessionSheet(
        orderId: widget.orderId,
        wageConfigs: _wageConfigs,
      ),
    );

    if (result == true) _loadAll();
  }

  Future<void> _confirmDelete(dynamic s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Sesi?'),
        content: Text(
          'Sesi ${_labelForSessionType(s['session_type'])} tanggal ${s['session_date']} akan dihapus.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.dio
          .delete('/admin/orders/${widget.orderId}/musician-sessions/${s['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi dihapus'), backgroundColor: AppColors.statusSuccess),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusDanger),
              const SizedBox(height: 12),
              Text(_error ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconForRole(String? role) {
    return switch (role) {
      'musisi' => Icons.music_note,
      'mc' => Icons.mic,
      'paduan_suara' => Icons.groups,
      _ => Icons.person,
    };
  }

  String _labelForRole(String? role) {
    return switch (role) {
      'musisi' => 'Musisi',
      'mc' => 'MC / Pembawa Acara',
      'paduan_suara' => 'Paduan Suara',
      _ => role ?? '-',
    };
  }

  String _labelForSessionType(String? type) {
    return switch (type) {
      'misa' => 'Misa',
      'doa_malam' => 'Doa Malam',
      'prosesi' => 'Prosesi',
      'pemberkatan' => 'Pemberkatan',
      'lainnya' => 'Lainnya',
      _ => type ?? '-',
    };
  }
}

/// Bottom sheet: form buat sesi musisi baru.
class _CreateSessionSheet extends StatefulWidget {
  final String orderId;
  final List<dynamic> wageConfigs;

  const _CreateSessionSheet({required this.orderId, required this.wageConfigs});

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  DateTime _sessionDate = DateTime.now();
  String _sessionType = 'misa';
  String _rateRole = 'musisi';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _locationCtrl = TextEditingController();
  final _countCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  double get _currentRate {
    final cfg = widget.wageConfigs.firstWhere(
      (c) => c['role_label'] == _rateRole,
      orElse: () => null,
    );
    return cfg == null ? 0 : (double.tryParse('${cfg['rate_per_session_per_person']}') ?? 0);
  }

  double get _previewTotal {
    final count = int.tryParse(_countCtrl.text) ?? 1;
    return _currentRate * count;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _countCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _api.dio.post(
        '/admin/orders/${widget.orderId}/musician-sessions',
        data: {
          'session_date': DateFormat('yyyy-MM-dd').format(_sessionDate),
          'session_type': _sessionType,
          'session_start_time': _startTime == null
              ? null
              : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
          'session_end_time': _endTime == null
              ? null
              : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
          'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          'musician_count': int.parse(_countCtrl.text),
          'rate_role': _rateRole,
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Tambah Sesi Musisi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Role
                DropdownButtonFormField<String>(
                  value: _rateRole,
                  decoration: const InputDecoration(
                    labelText: 'Peran',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.wageConfigs
                      .map((c) => DropdownMenuItem<String>(
                            value: c['role_label'] as String,
                            child: Text(_labelForRole(c['role_label'])),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _rateRole = v ?? 'musisi'),
                ),
                const SizedBox(height: 12),

                // Session type
                DropdownButtonFormField<String>(
                  value: _sessionType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Sesi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'misa', child: Text('Misa')),
                    DropdownMenuItem(value: 'doa_malam', child: Text('Doa Malam')),
                    DropdownMenuItem(value: 'prosesi', child: Text('Prosesi')),
                    DropdownMenuItem(value: 'pemberkatan', child: Text('Pemberkatan')),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setState(() => _sessionType = v ?? 'misa'),
                ),
                const SizedBox(height: 12),

                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _sessionDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _sessionDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Sesi',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_sessionDate)),
                  ),
                ),
                const SizedBox(height: 12),

                // Time range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _startTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Mulai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_startTime?.format(context) ?? '-'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Selesai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_endTime?.format(context) ?? '-'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Musician count
                TextFormField(
                  controller: _countCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Orang',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Minimal 1 orang';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Preview total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.roleSO.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.roleSO.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('Total Upah',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text(
                        _currency.format(_previewTotal),
                        style: const TextStyle(
                          color: AppColors.roleSO,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleSO,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Sesi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelForRole(String? role) {
    return switch (role) {
      'musisi' => 'Musisi',
      'mc' => 'MC',
      'paduan_suara' => 'Paduan Suara',
      _ => role ?? '-',
    };
  }
}
