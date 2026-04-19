import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Super Admin — kelola pekerja lepas (tukang jaga, tukang angkat peti, musisi).
///
/// Memory v1.40: Super Admin yang handle registrasi, perizinan, jadwal.
/// HRD hanya handle karyawan tetap. AI bantu rekomendasi assignment.
class SuperAdminFreelanceWorkerScreen extends StatefulWidget {
  const SuperAdminFreelanceWorkerScreen({super.key});

  @override
  State<SuperAdminFreelanceWorkerScreen> createState() =>
      _SuperAdminFreelanceWorkerScreenState();
}

class _SuperAdminFreelanceWorkerScreenState
    extends State<SuperAdminFreelanceWorkerScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late final TabController _tabs;
  bool _isLoading = true;
  List<dynamic> _workers = [];
  String _currentRole = 'tukang_jaga';

  static const _roleColor = AppColors.roleSuperAdmin;

  static const _tabRoles = ['tukang_jaga', 'tukang_angkat_peti', 'musisi'];
  static const _tabLabels = ['Tukang Jaga', 'Tukang Angkat Peti', 'Musisi'];
  static const _tabIcons = [
    Icons.shield_rounded,
    Icons.engineering_rounded,
    Icons.music_note_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _currentRole = _tabRoles[_tabs.index]);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/super-admin/users',
        queryParameters: {'role': _currentRole, 'per_page': 100},
      );
      if (res.data is Map && res.data['success'] == true) {
        final d = res.data['data'];
        if (d is List) {
          _workers = List<dynamic>.from(d);
        } else if (d is Map && d['data'] is List) {
          _workers = List<dynamic>.from(d['data']);
        }
      }
    } catch (e) {
      debugPrint('Freelance worker load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Pekerja Lepas',
        accentColor: _roleColor,
        showBack: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _roleColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: _roleColor,
          tabs: List.generate(_tabRoles.length, (i) {
            return Tab(
              icon: Icon(_tabIcons[i], size: 20),
              text: _tabLabels[i],
            );
          }),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _workers.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 140, 16, 80),
                      itemCount: _workers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildWorkerCard(_workers[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWorkerDialog(),
        backgroundColor: _roleColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildEmpty() {
    final label = _tabLabels[_tabs.index].toLowerCase();
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              const Icon(Icons.person_off_rounded,
                  size: 72, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                'Belum ada $label',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tambahkan pekerja baru dengan tombol + di bawah',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(dynamic w) {
    final name = (w['name']?.toString()) ?? '-';
    final phone = (w['phone']?.toString()) ?? '-';
    final email = (w['email']?.toString()) ?? '';
    final isActive = w['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _roleColor.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _roleColor.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _roleColor,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.statusSuccess.withValues(alpha: 0.12)
                  : AppColors.textHint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppColors.statusSuccess
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddWorkerDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password123');
    final label = _tabLabels[_tabs.index];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah $label'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (opsional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Default: password123 (bisa diubah)',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _roleColor),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, HP, dan password wajib diisi')),
      );
      return;
    }

    try {
      final res = await _api.dio.post('/super-admin/users', data: {
        'name': name,
        'phone': phone,
        'email': email.isEmpty ? null : email,
        'password': password,
        'role': _currentRole,
        'is_active': true,
      });
      if (res.data is Map && res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label "$name" berhasil ditambahkan')),
        );
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('422')
          ? 'Data tidak valid — mungkin HP sudah terdaftar'
          : 'Gagal menambah: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
