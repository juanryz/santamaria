import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/screens/role_inventory_screen.dart';
import '../../../shared/screens/role_fulfillment_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'dekor_daily_package_screen.dart';

class DekorDashboardScreen extends StatefulWidget {
  const DekorDashboardScreen({super.key});

  @override
  State<DekorDashboardScreen> createState() => _DekorDashboardScreenState();
}

class _DekorDashboardScreenState extends State<DekorDashboardScreen> {
  final _api = ApiClient();
  final _picker = ImagePicker();

  bool _isLoading = true;
  List<dynamic> _assignments = [];
  String _filter = 'pending';

  static const _filters = [
    ('pending', 'Menunggu'),
    ('confirmed', 'Dikonfirmasi'),
    ('done', 'Selesai'),
    ('rejected', 'Ditolak'),
  ];

  static const _roleColor = AppColors.roleDekor;

  String _statusOf(Map<String, dynamic> a) =>
      a['dekor_status'] as String? ?? 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/vendor/assignments');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _assignments = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat penugasan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doAction(String id, String action, {String? reason}) async {
    try {
      final data = reason != null ? {'reason': reason} : null;
      final res =
          await _api.dio.put('/vendor/assignments/$id/$action', data: data);
      if (!mounted) return;
      if (res.data['success'] == true) {
        final msg = switch (action) {
          'confirm' => 'Penugasan dikonfirmasi.',
          'reject' => 'Penugasan ditolak.',
          'done' => 'Penugasan diselesaikan.',
          _ => 'Berhasil.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status.')),
        );
      }
    }
  }

  Future<void> _confirm(String id) => _doAction(id, 'confirm');
  Future<void> _reject(String id, String reason) =>
      _doAction(id, 'reject', reason: reason);
  Future<void> _done(String id) => _doAction(id, 'done');

  Future<void> _promptReject(String id) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Penugasan?'),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Alasan penolakan (opsional)',
            labelText: 'Alasan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _reject(id, reasonCtrl.text.trim());
    }
  }

  Future<void> _uploadPhoto(String id) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(picked.path,
            filename: picked.name),
      });
      final res = await _api.dio.post(
        '/vendor/assignments/$id/photo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diunggah.')),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah foto.')),
        );
      }
    }
  }

  Color _statusColor(String s) => switch (s) {
        'confirmed' => AppColors.roleFinance,
        'done' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        _ => AppColors.statusWarning,
      };

  String _statusLabel(String s) => switch (s) {
        'confirmed' => 'Dikonfirmasi',
        'done' => 'Selesai',
        'rejected' => 'Ditolak',
        _ => 'Menunggu',
      };

  List<dynamic> get _filtered => _assignments
      .where((a) => _statusOf(Map<String, dynamic>.from(a)) == _filter)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Dashboard Dekorasi',
        accentColor: _roleColor,
        actions: [
          GlassIconButton(
            icon: Icons.refresh,
            onPressed: _load,
            color: AppColors.textSecondary,
            tooltip: 'Refresh',
          ),
          GlassIconButton(
            icon: Icons.logout,
            onPressed: _logout,
            color: AppColors.textSecondary,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick access: Paket Harian La Fiore
          _buildQuickAccess(),

          // Filter chips
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _filters.map((f) {
                  final isSelected = _filter == f.$1;
                  final count = _assignments
                      .where((a) =>
                          _statusOf(Map<String, dynamic>.from(a)) == f.$1)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label:
                          Text('${f.$2}${count > 0 ? " ($count)" : ""}'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = f.$1),
                      selectedColor: _roleColor,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Assignment list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Tidak ada penugasan.',
                                style: TextStyle(color: AppColors.textHint)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) =>
                                _buildCard(_filtered[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    final confirmedAssignments = _assignments
        .where(
            (a) => _statusOf(Map<String, dynamic>.from(a)) == 'confirmed')
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          // Stok Dekorasi — role-agnostic inventory
          _buildQuickAccessCard(
            icon: Icons.inventory_2_outlined,
            title: 'Stok Dekorasi',
            subtitle: 'Kelola inventaris bunga & material',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleInventoryScreen()),
            ),
          ),
          const SizedBox(height: 8),
          // Paket Harian La Fiore
          _buildQuickAccessCard(
            icon: Icons.local_florist,
            title: 'Paket Harian La Fiore',
            subtitle: confirmedAssignments.isNotEmpty
                ? '${confirmedAssignments.length} tugas aktif'
                : 'Belum ada tugas aktif',
            onTap: confirmedAssignments.isNotEmpty
                ? () {
                    final order = Map<String, dynamic>.from(
                        confirmedAssignments.first);
                    final orderId = order['order_id']?.toString() ??
                        order['id']?.toString() ??
                        '';
                    if (orderId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DekorDailyPackageScreen(orderId: orderId),
                        ),
                      );
                    }
                  }
                : null,
          ),
          const SizedBox(height: 8),
          // v1.39 — Cuti & Izin
          _buildQuickAccessCard(
            icon: Icons.event_available,
            title: 'Cuti & Izin Saya',
            subtitle: 'Request & lihat status cuti/sakit/izin',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyLeavesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GlassRoleWidget(
      roleColor: _roleColor,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _roleColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> assignment) {
    final status = _statusOf(assignment);
    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 18,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: order number + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment['order_number'] ?? 'Penugasan',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Deceased name
            Text(
              assignment['deceased_name'] ?? '-',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Service date
            if (assignment['service_date'] != null)
              _iconRow(Icons.calendar_today_outlined,
                  assignment['service_date'], AppColors.textSecondary),

            // Pickup address
            if (assignment['pickup_address'] != null) ...[
              const SizedBox(height: 4),
              _iconRow(Icons.location_on_outlined,
                  assignment['pickup_address'], AppColors.statusWarning),
            ],

            // Notes
            if (assignment['notes'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_outlined,
                        color: AppColors.textHint, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        assignment['notes'],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (isPending || isConfirmed) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _promptReject(assignment['id']),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusDanger,
                          side:
                              const BorderSide(color: AppColors.statusDanger),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirm(assignment['id']),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Konfirmasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roleColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                  if (isConfirmed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _done(assignment['id']),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Selesaikan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Upload photo button (for confirmed and done statuses)
            if (isConfirmed || status == 'done') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _uploadPhoto(assignment['id']),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Upload Bukti Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _roleColor,
                    side: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],

            // Quick access to checklist + daily package (for confirmed assignments)
            if (isConfirmed) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final orderId = assignment['order_id']?.toString() ??
                        assignment['id']?.toString() ??
                        '';
                    if (orderId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RoleFulfillmentScreen(orderId: orderId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.checklist_outlined, size: 16),
                  label: const Text('Checklist Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _roleColor,
                    side: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final orderId = assignment['order_id']?.toString() ??
                        assignment['id']?.toString() ??
                        '';
                    if (orderId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DekorDailyPackageScreen(orderId: orderId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.local_florist, size: 16),
                  label: const Text('Paket Harian La Fiore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _roleColor,
                    side: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      (_) => false,
    );
  }
}
