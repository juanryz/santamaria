import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.40 — Musician wage config: tarif per orang per sesi per role_label.
/// Super Admin / HRD / Purchasing kelola rate global.
class MusicianWageConfigScreen extends StatefulWidget {
  const MusicianWageConfigScreen({super.key});

  @override
  State<MusicianWageConfigScreen> createState() =>
      _MusicianWageConfigScreenState();
}

class _MusicianWageConfigScreenState extends State<MusicianWageConfigScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _configs = [];

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
      final res = await _api.dio.get('/admin/musicians/wage-configs');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() =>
            _configs = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat konfigurasi upah musisi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfigForm(existing: existing),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Tarif Musisi',
        accentColor: AppColors.brandAccent,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Tarif',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _configs.isEmpty
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
        title: 'Belum Ada Tarif',
        subtitle:
            'Tambah tarif per role (musisi, mc, paduan suara) yang berlaku untuk sesi order.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _configs.length,
        itemBuilder: (c, i) {
          final cfg = _configs[i] as Map<String, dynamic>;
          return _configCard(cfg);
        },
      );

  Widget _configCard(Map<String, dynamic> cfg) {
    final role = (cfg['role_label'] ?? '').toString();
    final rate = num.tryParse('${cfg['rate_per_session_per_person']}') ?? 0;
    final active = cfg['is_active'] == true;
    final eff = DateTime.tryParse(cfg['effective_date'] ?? '');
    final end = DateTime.tryParse(cfg['end_date'] ?? '');

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.brandAccent.withOpacity(0.25),
      onTap: () => _openForm(cfg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_roleLabel(role),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              GlassStatusBadge(
                label: active ? 'Aktif' : 'Nonaktif',
                color: active ? AppColors.statusSuccess : AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.payments,
                  size: 16, color: AppColors.brandPrimary),
              const SizedBox(width: 6),
              Text(
                NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0)
                    .format(rate),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary),
              ),
              const Text(' / orang / sesi',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.date_range,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                  eff != null
                      ? 'Berlaku ${DateFormat('d MMM yyyy', 'id_ID').format(eff)}${end != null ? ' – ${DateFormat('d MMM yyyy', 'id_ID').format(end)}' : ''}'
                      : '-',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) => switch (r) {
        'musisi' => 'Musisi',
        'mc' => 'MC / Pembawa Acara',
        'paduan_suara' => 'Paduan Suara',
        _ => r,
      };
}

// ─────────────────────────────────────────────────────────────
// Dialog form
// ─────────────────────────────────────────────────────────────

class _ConfigForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ConfigForm({this.existing});

  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  late String _role;
  final _rateCtrl = TextEditingController();
  late DateTime _effectiveDate;
  DateTime? _endDate;
  bool _active = true;
  bool _saving = false;

  static const _roles = ['musisi', 'mc', 'paduan_suara'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _role = e?['role_label'] ?? 'musisi';
    _rateCtrl.text = '${e?['rate_per_session_per_person'] ?? ''}';
    _effectiveDate = DateTime.tryParse(e?['effective_date'] ?? '') ??
        DateTime.now();
    _endDate = DateTime.tryParse(e?['end_date'] ?? '');
    _active = e?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'role_label': _role,
      'rate_per_session_per_person': num.tryParse(_rateCtrl.text) ?? 0,
      'effective_date': DateFormat('yyyy-MM-dd').format(_effectiveDate),
      if (_endDate != null)
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'is_active': _active,
    };

    try {
      final res = widget.existing != null
          ? await _api.dio.put(
              '/admin/musicians/wage-configs/${widget.existing!['id']}',
              data: body)
          : await _api.dio.post('/admin/musicians/wage-configs', data: body);
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
            content: Text('Gagal menyimpan tarif'),
            backgroundColor: AppColors.statusDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Tarif' : 'Tambah Tarif Musisi'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(_label(r))))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? 'musisi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarif per Orang per Sesi (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = num.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Masukkan tarif';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _effectiveDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Mulai Berlaku',
                      border: OutlineInputBorder()),
                  child: Text(
                      DateFormat('d MMM yyyy', 'id_ID').format(_effectiveDate)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ??
                        _effectiveDate.add(const Duration(days: 365)),
                    firstDate: _effectiveDate,
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Berakhir (opsional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : null,
                  ),
                  child: Text(_endDate == null
                      ? '—'
                      : DateFormat('d MMM yyyy', 'id_ID').format(_endDate!)),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Aktif'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  String _label(String r) => switch (r) {
        'musisi' => 'Musisi',
        'mc' => 'MC / Pembawa Acara',
        'paduan_suara' => 'Paduan Suara',
        _ => r,
      };
}
