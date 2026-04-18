import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/funeral_home_picker.dart';

/// v1.40 — Layanan Custom: multi rumah duka dalam 1 order.
/// Misal keluarga minta pindah rumah duka di tengah prosesi.
class CustomServicePhasesScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  const CustomServicePhasesScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<CustomServicePhasesScreen> createState() =>
      _CustomServicePhasesScreenState();
}

class _CustomServicePhasesScreenState extends State<CustomServicePhasesScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _phases = [];

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
      final res = await _api.dio.get('/so/orders/${widget.orderId}/phases');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _phases =
            List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat phase layanan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PhaseForm(
          orderId: widget.orderId,
          existing: existing,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _deletePhase(Map<String, dynamic> phase) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Hapus Phase?',
      message:
          'Phase ${phase['phase_sequence']} akan dihapus. Jika ini phase terakhir, order akan kembali bukan layanan custom.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;

    try {
      final res = await _api.dio
          .delete('/so/orders/${widget.orderId}/phases/${phase['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Phase dihapus'),
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
            content: Text('Gagal menghapus phase'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Layanan Custom — ${widget.orderNumber}',
        accentColor: AppColors.roleSO,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Tambah Phase',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _phases.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.place_outlined,
        title: 'Belum Ada Phase',
        subtitle:
            'Tambah phase jika keluarga minta pindah rumah duka di tengah prosesi. Extra fee dicatat otomatis.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _phases.length,
        itemBuilder: (c, i) {
          final phase = _phases[i] as Map<String, dynamic>;
          return _phaseCard(phase, i);
        },
      );

  Widget _phaseCard(Map<String, dynamic> p, int idx) {
    final fh = p['funeral_home'] as Map<String, dynamic>?;
    final start = DateTime.tryParse(p['start_date'] ?? '');
    final end = DateTime.tryParse(p['end_date'] ?? '');
    final seq = p['phase_sequence'] ?? (idx + 1);
    final activities = (p['activities'] ?? '').toString();
    final notes = (p['notes'] ?? '').toString();

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.roleSO.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandPrimary,
                radius: 16,
                child: Text('$seq',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    fh?['name'] ?? 'Rumah duka belum dipilih',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openForm(p);
                  if (v == 'delete') _deletePhase(p);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          if (fh != null && fh['city'] != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(fh['city'],
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                start != null && end != null
                    ? '${DateFormat('d MMM', 'id_ID').format(start)} – ${DateFormat('d MMM yyyy', 'id_ID').format(end)}'
                    : '-',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(activities,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
          ],
        ],
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
}

// ─────────────────────────────────────────────────────────────
// Form phase baru/edit
// ─────────────────────────────────────────────────────────────

class _PhaseForm extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? existing;
  const _PhaseForm({required this.orderId, this.existing});

  @override
  State<_PhaseForm> createState() => _PhaseFormState();
}

class _PhaseFormState extends State<_PhaseForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  String? _funeralHomeId;
  String? _funeralHomeName;
  DateTime? _startDate;
  DateTime? _endDate;
  final _activitiesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _extraFeeCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _funeralHomeId = e['funeral_home_id']?.toString();
      _funeralHomeName =
          (e['funeral_home'] as Map<String, dynamic>?)?['name'];
      _startDate = DateTime.tryParse(e['start_date'] ?? '');
      _endDate = DateTime.tryParse(e['end_date'] ?? '');
      _activitiesCtrl.text = e['activities'] ?? '';
      _notesCtrl.text = e['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _activitiesCtrl.dispose();
    _notesCtrl.dispose();
    _extraFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih tanggal mulai & akhir'),
            backgroundColor: AppColors.statusWarning),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal akhir harus setelah tanggal mulai'),
            backgroundColor: AppColors.statusDanger),
      );
      return;
    }

    setState(() => _saving = true);
    final body = {
      if (_funeralHomeId != null) 'funeral_home_id': _funeralHomeId,
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'activities': _activitiesCtrl.text.trim().isEmpty
          ? null
          : _activitiesCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      if (!_isEdit && _extraFeeCtrl.text.trim().isNotEmpty)
        'extra_fee': num.tryParse(_extraFeeCtrl.text) ?? 0,
    };

    try {
      final res = _isEdit
          ? await _api.dio.put(
              '/so/orders/${widget.orderId}/phases/${widget.existing!['id']}',
              data: body)
          : await _api.dio.post('/so/orders/${widget.orderId}/phases',
              data: body);
      if (!mounted) return;
      if (res.data['success'] == true) {
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
            content: Text('Gagal menyimpan phase'),
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
      appBar: GlassAppBar(
        title: _isEdit ? 'Edit Phase' : 'Tambah Phase Baru',
        accentColor: AppColors.roleSO,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Rumah Duka'),
            FuneralHomePicker(
              initialId: _funeralHomeId,
              initialName: _funeralHomeName,
              onSelected: (id, name) {
                setState(() {
                  _funeralHomeId = id;
                  _funeralHomeName = name;
                });
              },
            ),
            const SizedBox(height: 14),

            _label('Tanggal Mulai'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: _dec(icon: Icons.date_range),
                child: Text(_startDate == null
                    ? 'Pilih tanggal'
                    : DateFormat('EEEE, d MMM yyyy', 'id_ID')
                        .format(_startDate!)),
              ),
            ),
            const SizedBox(height: 10),

            _label('Tanggal Akhir'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: InputDecorator(
                decoration: _dec(icon: Icons.event_available),
                child: Text(_endDate == null
                    ? 'Pilih tanggal'
                    : DateFormat('EEEE, d MMM yyyy', 'id_ID')
                        .format(_endDate!)),
              ),
            ),
            const SizedBox(height: 14),

            _label('Aktivitas (opsional)'),
            TextFormField(
              controller: _activitiesCtrl,
              maxLines: 2,
              decoration: _dec(
                  icon: Icons.event_note,
                  hint: 'cth: Misa, prosesi, tahlil malam ke-3'),
            ),
            const SizedBox(height: 10),

            _label('Catatan (opsional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: _dec(icon: Icons.notes),
            ),
            const SizedBox(height: 14),

            if (!_isEdit) ...[
              _label('Biaya Tambahan (Rp, opsional)'),
              TextFormField(
                controller: _extraFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec(
                    icon: Icons.payments,
                    hint: 'Akan ditambahkan ke custom_service_extra_fee'),
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 10),
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
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Menyimpan…' : 'Simpan Phase'),
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
}
