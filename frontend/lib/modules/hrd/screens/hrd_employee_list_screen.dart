import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.35 — HRD: Manajemen Karyawan
/// HR dapat melihat, membuat, mengedit, dan menonaktifkan akun karyawan.
class HrdEmployeeListScreen extends StatefulWidget {
  const HrdEmployeeListScreen({super.key});

  @override
  State<HrdEmployeeListScreen> createState() => _HrdEmployeeListScreenState();
}

class _HrdEmployeeListScreenState extends State<HrdEmployeeListScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = AppColors.roleHrd;

  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/employees');
      if (res.data['success'] == true) {
        setState(
          () => _employees = List<dynamic>.from(res.data['data']['data'] ?? []),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _employees;
    final q = _search.toLowerCase();
    return _employees
        .where(
          (e) =>
              (e['name'] as String? ?? '').toLowerCase().contains(q) ||
              (e['role'] as String? ?? '').toLowerCase().contains(q) ||
              (e['phone'] as String? ?? '').contains(q),
        )
        .toList();
  }

  void _openForm({Map<String, dynamic>? employee}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _HrdEmployeeFormScreen(existing: employee),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> emp) async {
    final isActive = emp['is_active'] as bool? ?? true;
    final action = isActive ? 'deactivate' : 'activate';
    final label = isActive ? 'nonaktifkan' : 'aktifkan kembali';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${isActive ? 'Nonaktifkan' : 'Aktifkan'} Karyawan'),
        content: Text(
          '${isActive ? 'Nonaktifkan' : 'Aktifkan kembali'} akun ${emp['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.dio.put('/hrd/employees/${emp['id']}/$action');
      _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal $label karyawan.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Manajemen Karyawan',
        accentColor: _roleColor,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _roleColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Karyawan'),
        onPressed: () => _openForm(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama, role, atau nomor HP...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada karyawan ditemukan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _employeeCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final isActive = emp['is_active'] as bool? ?? true;
    final role = emp['role'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.15),
            child: Text(
              (emp['name'] as String? ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _roleColor,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  emp['name'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.grey).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.roleColor(role),
                ),
              ),
              Text(
                emp['phone'] ?? '-',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit')
                _openForm(employee: Map<String, dynamic>.from(emp));
              if (action == 'toggle') _toggleActive(emp);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.block : Icons.check_circle,
                      size: 16,
                      color: isActive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Buat / Edit Karyawan ────────────────────────────────────────────────

class _HrdEmployeeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _HrdEmployeeFormScreen({this.existing});

  @override
  State<_HrdEmployeeFormScreen> createState() => _HrdEmployeeFormScreenState();
}

class _HrdEmployeeFormScreenState extends State<_HrdEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  static const _roleColor = AppColors.roleHrd;
  bool _isSubmitting = false;
  bool _obscure = true;
  bool _locationConsent = false;
  String _selectedRole = 'service_officer';

  List<Map<String, dynamic>> _roles = [];
  bool _rolesLoading = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _nameCtrl.text = e['name'] ?? '';
      _emailCtrl.text = e['email'] ?? '';
      _phoneCtrl.text = e['phone'] ?? '';
      _selectedRole = e['role'] ?? 'service_officer';
    }
    _loadRoles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final res = await _api.dio.get('/super-admin/roles');
      final all = (res.data['data'] as List).cast<Map<String, dynamic>>();
      final filtered = all
          .where(
            (r) =>
                !['consumer', 'super_admin', 'owner'].contains(r['slug']) &&
                (r['is_active'] as bool? ?? true),
          )
          .toList();
      if (mounted) {
        setState(() {
          _roles = filtered;
          _rolesLoading = false;
          final slugs = filtered.map((r) => r['slug'] as String).toList();
          if (!slugs.contains(_selectedRole) && slugs.isNotEmpty) {
            _selectedRole = slugs.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && !_locationConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Centang persetujuan pemantauan lokasi terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEdit) {
        final data = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'role': _selectedRole,
        };
        if (_passwordCtrl.text.isNotEmpty) {
          await _api.dio.put(
            '/hrd/employees/${widget.existing!['id']}/reset-password',
            data: {'password': _passwordCtrl.text},
          );
        }
        await _api.dio.put(
          '/hrd/employees/${widget.existing!['id']}',
          data: data,
        );
      } else {
        await _api.dio.post(
          '/hrd/employees',
          data: {
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'password': _passwordCtrl.text,
            'role': _selectedRole,
            'location_consent': true,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Data karyawan diperbarui.'
                : 'Karyawan berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan data.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _isEdit ? 'Edit Karyawan' : 'Tambah Karyawan',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Data Karyawan'),
              const SizedBox(height: 12),
              _field(
                _nameCtrl,
                'Nama Lengkap *',
                Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _field(
                _emailCtrl,
                'Email *',
                Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email tidak valid'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                _phoneCtrl,
                'Nomor HP *',
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.textPrimary),
                validator: _isEdit
                    ? (v) => (v != null && v.isNotEmpty && v.length < 8)
                          ? 'Min 8 karakter'
                          : null
                    : (v) => (v == null || v.length < 8)
                          ? 'Password min 8 karakter'
                          : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  labelText: _isEdit
                      ? 'Password Baru (kosongkan jika tidak diubah)'
                      : 'Password *',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Role *'),
              const SizedBox(height: 10),
              _rolesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      initialValue:
                          _roles.any((r) => r['slug'] == _selectedRole)
                          ? _selectedRole
                          : null,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        labelText: 'Role',
                      ),
                      items: _roles
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r['slug'] as String,
                              child: Text(
                                r['label'] as String? ?? r['slug'] as String,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedRole = v);
                        }
                      },
                    ),

              // Consent — hanya saat tambah karyawan baru
              if (!_isEdit) ...[
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: _locationConsent
                        ? AppColors.brandPrimary.withValues(alpha: 0.06)
                        : Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _locationConsent
                          ? AppColors.brandPrimary.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _locationConsent,
                    onChanged: (v) =>
                        setState(() => _locationConsent = v ?? false),
                    activeColor: AppColors.brandPrimary,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Karyawan menyetujui pemantauan lokasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'HR mewakili karyawan dalam menyetujui bahwa lokasi mereka dipantau selama jam kerja untuk keperluan operasional.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Menyimpan...'
                        : (_isEdit ? 'Perbarui' : 'Simpan Karyawan'),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: _roleColor,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 1,
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppColors.textPrimary),
    validator: validator,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      labelText: label,
    ),
  );
}
