import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.40 — Musician sessions per order.
/// Bayaran per ORANG per SESI. Admin/SO input per sesi (misa, doa malam, dll).
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
  bool _loading = true;
  String? _error;
  List<dynamic> _sessions = [];

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
      final res = await _api.dio
          .get('/admin/orders/${widget.orderId}/musician-sessions');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() =>
            _sessions = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat sesi musisi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _MusicianSessionForm(
          orderId: widget.orderId,
          existing: existing,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _deleteSession(Map<String, dynamic> s) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Hapus Sesi Musisi?',
      message:
          'Sesi ${s['session_type']} pada ${s['session_date']} akan dihapus.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;

    try {
      final res = await _api.dio
          .delete('/admin/orders/${widget.orderId}/musician-sessions/${s['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res.data['message'] ?? 'Sesi dihapus'),
            backgroundColor: AppColors.statusSuccess),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menghapus sesi'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Sesi Musisi — ${widget.orderNumber}',
        accentColor: AppColors.brandAccent,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Sesi',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _sessions.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
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

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.music_note_outlined,
        title: 'Belum Ada Sesi Musisi',
        subtitle: 'Tambah sesi (misa, doa malam, dll) untuk order ini.',
      );

  Widget _buildList() {
    final totalWage = _sessions.fold<num>(
        0, (sum, s) => sum + (num.tryParse('${s['total_wage']}') ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        GlassWidget(
          padding: const EdgeInsets.all(16),
          tint: AppColors.brandAccent.withOpacity(0.12),
          borderColor: AppColors.brandAccent.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Upah Musisi',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(_rp(totalWage),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._sessions.map((s) => _sessionCard(s as Map<String, dynamic>)),
      ],
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final date = DateTime.tryParse(s['session_date'] ?? '');
    final dateLabel = date != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(date)
        : (s['session_date'] ?? '-');
    final type = (s['session_type'] ?? '').toString();
    final count = s['musician_count'] ?? 0;
    final rate = num.tryParse('${s['rate_per_person']}') ?? 0;
    final total = num.tryParse('${s['total_wage']}') ?? 0;
    final startTime = s['session_start_time'];
    final location = s['location'];

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.brandAccent.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_typeLabel(type)} • $dateLabel${startTime != null ? ' $startTime' : ''}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openForm(s);
                  if (v == 'delete') _deleteSession(s);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          if (location != null && location.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(location,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint))),
            ]),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('$count orang'),
              const SizedBox(width: 8),
              _chip('@ ${_rp(rate)}'),
              const Spacer(),
              Text(_rp(total),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.brandSecondary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary)),
      );

  String _typeLabel(String t) => switch (t) {
        'misa' => 'Misa',
        'doa_malam' => 'Doa Malam',
        'prosesi' => 'Prosesi',
        'pemberkatan' => 'Pemberkatan',
        _ => 'Lainnya',
      };

  String _rp(num v) => NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(v);
}

// ─────────────────────────────────────────────────────────────────────
// Form screen — tambah/edit sesi musisi
// ─────────────────────────────────────────────────────────────────────

class _MusicianSessionForm extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? existing;
  const _MusicianSessionForm({required this.orderId, this.existing});

  @override
  State<_MusicianSessionForm> createState() => _MusicianSessionFormState();
}

class _MusicianSessionFormState extends State<_MusicianSessionForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late DateTime _sessionDate;
  late String _sessionType;
  final _locationCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  TimeOfDay? _startTime;
  bool _saving = false;

  static const _types = ['misa', 'doa_malam', 'prosesi', 'pemberkatan', 'lainnya'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _sessionDate = e?['session_date'] != null
        ? DateTime.parse(e!['session_date'])
        : DateTime.now();
    _sessionType = e?['session_type'] ?? 'misa';
    _locationCtrl.text = e?['location'] ?? '';
    _countCtrl.text = '${e?['musician_count'] ?? ''}';
    _rateCtrl.text = '${e?['rate_per_person'] ?? ''}';
    if (e?['session_start_time'] != null) {
      final parts = (e!['session_start_time'] as String).split(':');
      if (parts.length >= 2) {
        _startTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _countCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'session_date': DateFormat('yyyy-MM-dd').format(_sessionDate),
      'session_type': _sessionType,
      if (_startTime != null)
        'session_start_time':
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'musician_count': int.tryParse(_countCtrl.text) ?? 1,
      'rate_per_person': num.tryParse(_rateCtrl.text) ?? 0,
    };

    try {
      final existing = widget.existing;
      final res = existing != null
          ? await _api.dio.put(
              '/admin/orders/${widget.orderId}/musician-sessions/${existing['id']}',
              data: body)
          : await _api.dio.post(
              '/admin/orders/${widget.orderId}/musician-sessions',
              data: body);
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Tersimpan'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal menyimpan'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyimpan sesi'),
            backgroundColor: AppColors.statusDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (int.tryParse(_countCtrl.text) ?? 0) *
        (num.tryParse(_rateCtrl.text) ?? 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.existing != null ? 'Edit Sesi' : 'Tambah Sesi Musisi',
        accentColor: AppColors.brandAccent,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Tanggal'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _sessionDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) setState(() => _sessionDate = picked);
              },
              child: InputDecorator(
                decoration: _dec(icon: Icons.calendar_today),
                child: Text(DateFormat('EEEE, d MMM yyyy', 'id_ID')
                    .format(_sessionDate)),
              ),
            ),
            const SizedBox(height: 12),

            _label('Jam Mulai (opsional)'),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now());
                if (picked != null) setState(() => _startTime = picked);
              },
              child: InputDecorator(
                decoration: _dec(icon: Icons.access_time),
                child: Text(_startTime == null
                    ? 'Pilih jam'
                    : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 12),

            _label('Jenis Sesi'),
            DropdownButtonFormField<String>(
              value: _sessionType,
              decoration: _dec(icon: Icons.music_note),
              items: _types
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _sessionType = v ?? 'misa'),
            ),
            const SizedBox(height: 12),

            _label('Lokasi (opsional)'),
            TextFormField(
              controller: _locationCtrl,
              decoration: _dec(icon: Icons.place, hint: 'Rumah duka / gereja'),
            ),
            const SizedBox(height: 12),

            _label('Jumlah Musisi'),
            TextFormField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(icon: Icons.people, hint: 'cth: 5'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Masukkan jumlah musisi';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            _label('Rate per Orang (Rp)'),
            TextFormField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(icon: Icons.payments, hint: 'cth: 150000'),
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Masukkan rate per orang';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            GlassWidget(
              padding: const EdgeInsets.all(14),
              tint: AppColors.brandPrimary.withOpacity(0.08),
              borderColor: AppColors.brandPrimary.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Upah Sesi',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(
                      NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0)
                          .format(total),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Menyimpan…' : 'Simpan Sesi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(s,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  InputDecoration _dec({IconData? icon, String? hint}) => InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  String _typeLabel(String t) => switch (t) {
        'misa' => 'Misa',
        'doa_malam' => 'Doa Malam',
        'prosesi' => 'Prosesi',
        'pemberkatan' => 'Pemberkatan',
        _ => 'Lainnya',
      };
}
