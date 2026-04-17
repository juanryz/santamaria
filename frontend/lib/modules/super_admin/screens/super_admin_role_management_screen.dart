import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class SuperAdminRoleManagementScreen extends StatefulWidget {
  final ApiClient apiClient;

  const SuperAdminRoleManagementScreen({super.key, required this.apiClient});

  @override
  State<SuperAdminRoleManagementScreen> createState() =>
      _SuperAdminRoleManagementScreenState();
}

class _SuperAdminRoleManagementScreenState
    extends State<SuperAdminRoleManagementScreen> {
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.apiClient.dio.get('/super-admin/roles');
      final data = res.data['data'] as List;
      setState(() {
        _roles = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat roles: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> role) async {
    final slug = role['slug'] as String;
    // Do not allow toggling super_admin or consumer
    if (slug == 'super_admin' || slug == 'consumer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role ini tidak dapat dinonaktifkan.')),
      );
      return;
    }
    try {
      await widget.apiClient.dio.put(
        '/super-admin/roles/${role['id']}',
        data: {'is_active': !(role['is_active'] as bool)},
      );
      await _loadRoles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final userCount = role['user_count'] ?? 0;
    final warning = userCount > 0
        ? 'Hapus role "${role['label']}" (${role['slug']})?\n\nPeringatan: $userCount pengguna masih menggunakan role ini.'
        : 'Hapus role "${role['label']}" (${role['slug']})?';

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus Role',
      message: warning,
      confirmLabel: 'Hapus',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    );

    if (!confirmed) return;

    try {
      await widget.apiClient.dio.delete('/super-admin/roles/${role['id']}');
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role berhasil dihapus.')),
        );
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  String _extractErrorMessage(dynamic e) {
    try {
      final response = (e as dynamic).response;
      if (response != null && response.data is Map) {
        return response.data['message'] ?? 'Terjadi kesalahan.';
      }
    } catch (_) {}
    return 'Terjadi kesalahan: $e';
  }

  Future<void> _showRoleForm({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RoleFormDialog(
        apiClient: widget.apiClient,
        existing: existing,
      ),
    );
    if (result == true) await _loadRoles();
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.brandPrimary;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.roleSuperAdmin.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(
                  title: 'Manajemen Role',
                  showBack: true,
                  accentColor: AppColors.roleSuperAdmin,
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!,
                                      style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadRoles,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRoles,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: _roles.length,
                                itemBuilder: (ctx, i) =>
                                    _RoleTile(
                                      role: _roles[i],
                                      onToggleActive: () =>
                                          _toggleActive(_roles[i]),
                                      onEdit: () =>
                                          _showRoleForm(existing: _roles[i]),
                                      onDelete: () => _deleteRole(_roles[i]),
                                      parseColor: _parseColor,
                                    ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoleForm(),
        backgroundColor: AppColors.roleSuperAdmin,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Role',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Role Tile ──────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  final Map<String, dynamic> role;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(String?) parseColor;

  const _RoleTile({
    required this.role,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSystem = role['is_system'] as bool? ?? false;
    final isActive = role['is_active'] as bool? ?? true;
    final color = parseColor(role['color_hex'] as String?);
    final userCount = role['user_count'] ?? 0;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      tint: isActive ? AppColors.glassWhite : AppColors.glassWhite.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Color indicator
              Container(
                width: 4, height: 40,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role['label'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                        if (isSystem) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock, size: 14, color: AppColors.textHint),
                        ],
                        const Spacer(),
                        // User count badge
                        if (userCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$userCount user',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      role['slug'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Feature chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (role['can_have_inventory'] == true)
                _FlagChip(label: 'Inventaris', color: Colors.amber),
              if (role['is_vendor'] == true)
                _FlagChip(label: 'Vendor', color: Colors.purple),
              if (role['can_manage_orders'] == true)
                _FlagChip(label: 'Manage Order', color: Colors.blue),
              if (role['receives_order_alarm'] == true)
                _FlagChip(label: 'Terima Alarm', color: Colors.orange),
              if (role['is_viewer_only'] == true)
                _FlagChip(label: 'View Only', color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Toggle active (system roles except super_admin/consumer)
              if (isSystem &&
                  role['slug'] != 'super_admin' &&
                  role['slug'] != 'consumer')
                TextButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: isActive ? Colors.orange : Colors.green,
                  ),
                  label: Text(
                    isActive ? 'Nonaktifkan' : 'Aktifkan',
                    style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.orange : Colors.green),
                  ),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4)),
                ),
              // Edit (any role)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16, color: AppColors.brandPrimary),
                label: const Text('Edit',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.brandPrimary)),
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
              // Delete (custom roles only)
              if (!isSystem)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Hapus',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FlagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85)),
      ),
    );
  }
}

// ── Role Form Dialog ───────────────────────────────────────────────────────────

class _RoleFormDialog extends StatefulWidget {
  final ApiClient apiClient;
  final Map<String, dynamic>? existing;

  const _RoleFormDialog({required this.apiClient, this.existing});

  @override
  State<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<_RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();

  bool _canHaveInventory = false;
  bool _isVendor = false;
  bool _canManageOrders = false;
  bool _receivesOrderAlarm = false;
  bool _isViewerOnly = false;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;
  bool get _isSystem => widget.existing?['is_system'] as bool? ?? false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _slugCtrl.text = e['slug'] ?? '';
      _labelCtrl.text = e['label'] ?? '';
      _descCtrl.text = e['description'] ?? '';
      _colorCtrl.text = e['color_hex'] ?? '';
      _iconCtrl.text = e['icon_name'] ?? '';
      _canHaveInventory = e['can_have_inventory'] as bool? ?? false;
      _isVendor = e['is_vendor'] as bool? ?? false;
      _canManageOrders = e['can_manage_orders'] as bool? ?? false;
      _receivesOrderAlarm = e['receives_order_alarm'] as bool? ?? false;
      _isViewerOnly = e['is_viewer_only'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _labelCtrl.dispose();
    _descCtrl.dispose();
    _colorCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final body = <String, dynamic>{
      'label': _labelCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'can_have_inventory': _canHaveInventory,
      'is_vendor': _isVendor,
      'can_manage_orders': _canManageOrders,
      'receives_order_alarm': _receivesOrderAlarm,
      'is_viewer_only': _isViewerOnly,
      if (_colorCtrl.text.trim().isNotEmpty) 'color_hex': _colorCtrl.text.trim(),
      if (_iconCtrl.text.trim().isNotEmpty) 'icon_name': _iconCtrl.text.trim(),
    };

    // slug: only include for new roles or non-system edit
    if (!_isEdit || !_isSystem) {
      body['slug'] = _slugCtrl.text.trim();
    }

    try {
      if (_isEdit) {
        await widget.apiClient.dio
            .put('/super-admin/roles/${widget.existing!['id']}', data: body);
      } else {
        await widget.apiClient.dio.post('/super-admin/roles', data: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      String msg = 'Terjadi kesalahan.';
      try {
        final response = (e as dynamic).response;
        if (response?.data is Map) {
          final errors = response.data['errors'];
          if (errors is Map) {
            msg = errors.values.first.toString().replaceAll('[', '').replaceAll(']', '');
          } else {
            msg = response.data['message'] ?? msg;
          }
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Role' : 'Tambah Role Baru',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Slug (disabled for system roles in edit mode)
              TextFormField(
                controller: _slugCtrl,
                enabled: !(_isEdit && _isSystem),
                decoration: const InputDecoration(
                  labelText: 'Slug *',
                  hintText: 'contoh: vendor_bunga (huruf kecil, underscore)',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                ],
                validator: (v) {
                  if (_isEdit && _isSystem) return null;
                  if (v == null || v.isEmpty) return 'Slug wajib diisi';
                  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
                    return 'Hanya huruf kecil, angka, dan underscore';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Role *',
                  hintText: 'contoh: Vendor Bunga Baru',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama role wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Fitur & Akses',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),

              _FlagSwitch(
                label: 'Punya Inventaris',
                subtitle: 'Dapat menggunakan /role-stock endpoints',
                value: _canHaveInventory,
                onChanged: (v) => setState(() => _canHaveInventory = v),
              ),
              _FlagSwitch(
                label: 'Vendor Eksternal',
                subtitle: 'Role vendor / penyedia layanan',
                value: _isVendor,
                onChanged: (v) => setState(() => _isVendor = v),
              ),
              _FlagSwitch(
                label: 'Kelola Order',
                subtitle: 'Dapat melihat & mengelola order',
                value: _canManageOrders,
                onChanged: (v) => setState(() => _canManageOrders = v),
              ),
              _FlagSwitch(
                label: 'Terima Notifikasi Order',
                subtitle: 'Mendapat alarm saat order dikonfirmasi',
                value: _receivesOrderAlarm,
                onChanged: (v) => setState(() => _receivesOrderAlarm = v),
              ),
              _FlagSwitch(
                label: 'Hanya Lihat (Read-only)',
                subtitle: 'Tidak dapat melakukan perubahan data',
                value: _isViewerOnly,
                onChanged: (v) => setState(() => _isViewerOnly = v),
              ),
              const SizedBox(height: 12),

              // Color hex
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Warna Hex (opsional)',
                  hintText: '#4CAF50',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
                    return 'Format: #RRGGBB';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Icon name
              TextFormField(
                controller: _iconCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Ikon Material (opsional)',
                  hintText: 'warehouse, store, camera_alt ...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isEdit ? 'Simpan' : 'Buat Role',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FlagSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.brandPrimary,
    );
  }
}
