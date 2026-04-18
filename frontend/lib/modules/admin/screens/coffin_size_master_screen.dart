import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.40 — Master ukuran peti + rekomendasi jumlah tukang angkat.
///
/// Super Admin only. Dipakai saat SO konfirmasi order untuk
/// auto-suggest jumlah tukang angkat peti sesuai ukuran.
class CoffinSizeMasterScreen extends StatefulWidget {
  const CoffinSizeMasterScreen({super.key});

  @override
  State<CoffinSizeMasterScreen> createState() => _CoffinSizeMasterScreenState();
}

class _CoffinSizeMasterScreenState extends State<CoffinSizeMasterScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _sizes = [];

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
      final res = await _api.dio.get('/admin/coffin-sizes');
      if (!mounted) return;
      setState(() {
        _sizes = (res.data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat ukuran peti.';
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CoffinSizeForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete(Map<String, dynamic> size) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ukuran?'),
        content: Text(
          'Ukuran "${size['size_label']}" akan dihapus. '
          'Kalau sudah dipakai di order, akan otomatis dinon-aktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
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
      final res = await _api.dio.delete('/admin/coffin-sizes/${size['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Berhasil'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Ukuran Peti',
        accentColor: AppColors.brandAccent,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Ukuran', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _sizes.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          message: 'Belum ada ukuran peti.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _sizes.length,
                        itemBuilder: (_, i) => _buildCard(_sizes[i]),
                      ),
      ),
    );
  }

  Widget _buildCard(dynamic s) {
    final isActive = s['is_active'] == true;
    final label = s['size_label'] as String? ?? '-';
    final minLen = s['min_length_cm'];
    final maxLen = s['max_length_cm'];
    final liftersMin = s['recommended_lifters_min'] as int? ?? 0;
    final liftersMax = s['recommended_lifters_max'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: (isActive ? AppColors.brandAccent : AppColors.textHint).withValues(alpha: 0.25),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: AppColors.brandAccent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NONAKTIF',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.straighten, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  minLen != null && maxLen != null
                      ? '$minLen - $maxLen cm'
                      : 'Panjang tidak diset',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.groups, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  liftersMin == liftersMax
                      ? '$liftersMin orang'
                      : '$liftersMin-$liftersMax orang',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openForm(Map<String, dynamic>.from(s)),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: AppColors.brandAccent,
                      side: BorderSide(color: AppColors.brandAccent.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmDelete(Map<String, dynamic>.from(s)),
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog form untuk create/edit ukuran peti.
class _CoffinSizeForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _CoffinSizeForm({this.existing});

  @override
  State<_CoffinSizeForm> createState() => _CoffinSizeFormState();
}

class _CoffinSizeFormState extends State<_CoffinSizeForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _minLenCtrl;
  late final TextEditingController _maxLenCtrl;
  late final TextEditingController _liftersMinCtrl;
  late final TextEditingController _liftersMaxCtrl;
  late final TextEditingController _sortOrderCtrl;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    _labelCtrl = TextEditingController(text: e['size_label'] ?? '');
    _minLenCtrl = TextEditingController(text: e['min_length_cm']?.toString() ?? '');
    _maxLenCtrl = TextEditingController(text: e['max_length_cm']?.toString() ?? '');
    _liftersMinCtrl = TextEditingController(text: e['recommended_lifters_min']?.toString() ?? '4');
    _liftersMaxCtrl = TextEditingController(text: e['recommended_lifters_max']?.toString() ?? '4');
    _sortOrderCtrl = TextEditingController(text: e['sort_order']?.toString() ?? '0');
    _isActive = (e['is_active'] ?? true) == true;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _minLenCtrl.dispose();
    _maxLenCtrl.dispose();
    _liftersMinCtrl.dispose();
    _liftersMaxCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'size_label': _labelCtrl.text.trim(),
      'min_length_cm': int.tryParse(_minLenCtrl.text),
      'max_length_cm': int.tryParse(_maxLenCtrl.text),
      'recommended_lifters_min': int.parse(_liftersMinCtrl.text),
      'recommended_lifters_max': int.parse(_liftersMaxCtrl.text),
      'sort_order': int.tryParse(_sortOrderCtrl.text) ?? 0,
      'is_active': _isActive,
    };

    try {
      if (_isEdit) {
        await _api.dio.put('/admin/coffin-sizes/${widget.existing!['id']}', data: payload);
      } else {
        await _api.dio.post('/admin/coffin-sizes', data: payload);
      }
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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Ukuran' : 'Tambah Ukuran'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label *',
                  hintText: 'kecil / standard / medium / besar / jumbo',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minLenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Min Panjang (cm)',
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _maxLenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Panjang (cm)',
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _liftersMinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Min Pekerja *',
                        suffixText: 'orang',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 2) return 'Min 2';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _liftersMaxCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Pekerja *',
                        suffixText: 'orang',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        final min = int.tryParse(_liftersMinCtrl.text) ?? 0;
                        if (n == null || n < min) return 'Harus ≥ min';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sortOrderCtrl,
                decoration: const InputDecoration(labelText: 'Urutan Tampil'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Aktif'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
