import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'super_admin_user_form_screen.dart';

class SuperAdminUserListScreen extends StatefulWidget {
  final ApiClient apiClient;

  const SuperAdminUserListScreen({super.key, required this.apiClient});

  @override
  State<SuperAdminUserListScreen> createState() =>
      _SuperAdminUserListScreenState();
}

class _SuperAdminUserListScreenState extends State<SuperAdminUserListScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String _filterRole = 'all';
  final _searchController = TextEditingController();

  static const _roleColor = AppColors.roleSuperAdmin;

  static const _roleOptions = [
    'all', 'service_officer', 'admin', 'gudang', 'finance',
    'driver', 'dekor', 'konsumsi', 'supplier', 'owner',
    'pemuka_agama', 'tukang_angkat_peti',
  ];

  static const _roleLabels = {
    'all': 'Semua',
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
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterRole != 'all') params['role'] = _filterRole;
      if (_searchController.text.isNotEmpty) {
        params['search'] = _searchController.text;
      }

      final response = await widget.apiClient.dio
          .get('/super-admin/users', queryParameters: params);
      if (!mounted) return;
      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _users = List<dynamic>.from(data['data'] ?? data ?? []);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar pengguna.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool? ?? true;
    final action = isActive ? 'Nonaktifkan' : 'Aktifkan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Akun?'),
        content: Text('$action akun ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? AppColors.statusDanger
                  : AppColors.statusSuccess,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final endpoint = isActive
          ? '/super-admin/users/${user['id']}/deactivate'
          : '/super-admin/users/${user['id']}/activate';
      await widget.apiClient.dio.put(endpoint);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Akun berhasil ${isActive ? 'dinonaktifkan' : 'diaktifkan'}.')),
      );
      await _loadUsers();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status akun.')),
        );
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text('Yakin ingin meriset password ${user['name']} ke default (santa123)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleSuperAdmin),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.apiClient.dio.put('/super-admin/users/${user['id']}/reset-password');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil direset ke default.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal meriset password.')),
        );
      }
    }
  }

  Color _userRoleColor(String role) => AppColors.roleColor(role);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Kelola Pengguna',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SuperAdminUserFormScreen(apiClient: widget.apiClient),
                ),
              );
              _loadUsers();
            },
            child: const Icon(Icons.person_add_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.textHint, size: 20),
                    hintText: 'Cari nama, email, atau HP...',
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roleOptions.length,
                    itemBuilder: (context, i) {
                      final role = _roleOptions[i];
                      final isSelected = role == _filterRole;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_roleLabels[role] ?? role),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _filterRole = role);
                            _loadUsers();
                          },
                          selectedColor: _roleColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _users.isEmpty
                        ? const Center(
                            child: Text('Tidak ada pengguna ditemukan.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user =
                                  Map<String, dynamic>.from(_users[index]);
                              final isActive =
                                  user['is_active'] as bool? ?? true;
                              final role = user['role'] as String? ?? '';
                              final rColor = _userRoleColor(role);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: GlassWidget(
                                  borderRadius: 18,
                                  blurSigma: 16,
                                  tint: AppColors.glassWhite,
                                  borderColor: AppColors.glassBorder,
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            rColor.withValues(alpha: 0.15),
                                        child: Text(
                                          (user['name'] as String? ??
                                              '?')[0].toUpperCase(),
                                          style: TextStyle(
                                              color: rColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name'] ?? '-',
                                              style: TextStyle(
                                                color: isActive
                                                    ? AppColors.textPrimary
                                                    : AppColors.textHint,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                                user['email'] ??
                                                    user['phone'] ??
                                                    '-',
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: rColor.withValues(
                                                        alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    (_roleLabels[role] ??
                                                        role),
                                                    style: TextStyle(
                                                        color: rColor,
                                                        fontSize: 11),
                                                  ),
                                                ),
                                                if (!isActive) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.statusDanger
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Text(
                                                        'Nonaktif',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .statusDanger,
                                                            fontSize: 11)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            color: AppColors.textSecondary),
                                        onSelected: (val) async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          if (val == 'toggle') {
                                            _toggleActive(user);
                                          }
                                          if (val == 'edit') {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    SuperAdminUserFormScreen(
                                                  apiClient: widget.apiClient,
                                                  existingUser: user,
                                                ),
                                              ),
                                            );
                                            _loadUsers();
                                          }
                                          if (val == 'reset') {
                                            _resetPassword(user);
                                          }
                                          if (val == 'verify') {
                                            try {
                                              await widget.apiClient.dio.put(
                                                  '/super-admin/users/${user['id']}/verify-supplier');
                                              if (mounted) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Supplier berhasil diverifikasi.')),
                                                );
                                                _loadUsers();
                                              }
                                            } catch (_) {}
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit')),
                                          const PopupMenuItem(
                                              value: 'reset',
                                              child: Text('Reset Password')),
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(
                                              isActive
                                                  ? 'Nonaktifkan'
                                                  : 'Aktifkan',
                                              style: TextStyle(
                                                  color: isActive
                                                      ? AppColors.statusDanger
                                                      : AppColors
                                                          .statusSuccess),
                                            ),
                                          ),
                                          if (role == 'supplier' &&
                                              user['is_verified_supplier'] !=
                                                  true)
                                            const PopupMenuItem(
                                              value: 'verify',
                                              child: Text(
                                                  'Verifikasi Supplier',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .roleFinance)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
