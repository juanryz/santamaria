import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SuperAdminUserFormScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Map<String, dynamic>? existingUser;

  const SuperAdminUserFormScreen({
    super.key,
    required this.apiClient,
    this.existingUser,
  });

  @override
  State<SuperAdminUserFormScreen> createState() =>
      _SuperAdminUserFormScreenState();
}

class _SuperAdminUserFormScreenState extends State<SuperAdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _religionController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String _selectedRole = 'service_officer';

  bool get _isEdit => widget.existingUser != null;

  static const _roleColor = AppColors.roleSuperAdmin;

  static const _roleOptions = [
    'service_officer', 'admin', 'gudang', 'finance', 'driver',
    'dekor', 'konsumsi', 'supplier', 'owner', 'pemuka_agama', 'tukang_angkat_peti',
  ];

  static const _roleLabels = {
    'service_officer': 'Service Officer',
    'admin': 'Admin',
    'gudang': 'Gudang',
    'finance': 'Finance',
    'driver': 'Driver',
    'dekor': 'Dekor',
    'konsumsi': 'Konsumsi',
    'supplier': 'Supplier',
    'owner': 'Owner',
    'pemuka_agama': 'Pemuka Agama',
    'tukang_angkat_peti': 'Koordinator Angkat Peti',
  };

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final u = widget.existingUser!;
      _nameController.text = u['name'] ?? '';
      _emailController.text = u['email'] ?? '';
      _phoneController.text = u['phone'] ?? '';
      _religionController.text = u['religion'] ?? '';
      _selectedRole = u['role'] ?? 'service_officer';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _religionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (_isEdit) {
        final data = <String, dynamic>{
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
        };
        if (_religionController.text.trim().isNotEmpty) {
          data['religion'] = _religionController.text.trim();
        }
        if (_passwordController.text.isNotEmpty) {
          await widget.apiClient.dio.put(
            '/super-admin/users/${widget.existingUser!['id']}/reset-password',
            data: {'password': _passwordController.text},
          );
        }
        await widget.apiClient.dio
            .put('/super-admin/users/${widget.existingUser!['id']}', data: data);
      } else {
        await widget.apiClient.dio.post('/super-admin/users', data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
          if (_religionController.text.trim().isNotEmpty)
            'religion': _religionController.text.trim(),
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _isEdit ? 'Akun berhasil diperbarui.' : 'Akun berhasil dibuat.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data akun.')),
        );
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
        title: _isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
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
              Text('Data Pengguna',
                  style: TextStyle(
                      color: _roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1)),
              const SizedBox(height: 16),
              _field(
                controller: _nameController,
                label: 'Nama Lengkap *',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _emailController,
                label: 'Email *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Nomor HP *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nomor HP wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                validator: _isEdit
                    ? (v) => (v != null && v.isNotEmpty && v.length < 8)
                        ? 'Minimal 8 karakter'
                        : null
                    : (v) => (v == null || v.length < 8)
                        ? 'Password minimal 8 karakter'
                        : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textHint, size: 20),
                  labelText: _isEdit
                      ? 'Password Baru (kosongkan jika tidak diubah)'
                      : 'Password *',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textHint,
                        size: 18),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Role *',
                  style: TextStyle(
                      color: _roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined,
                      color: AppColors.textHint, size: 20),
                  labelText: 'Role',
                ),
                items: _roleOptions
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(_roleLabels[role] ?? role),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedRole = val!),
              ),
              if (_selectedRole == 'pemuka_agama') ...[
                const SizedBox(height: 12),
                _field(
                  controller: _religionController,
                  label: 'Agama yang Dilayani',
                  icon: Icons.church_outlined,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSubmitting
                      ? 'Menyimpan...'
                      : (_isEdit ? 'Perbarui Akun' : 'Buat Akun')),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
          labelText: label,
        ),
      );
}
