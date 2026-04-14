import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';

class VendorAssignmentScreen extends StatefulWidget {
  const VendorAssignmentScreen({super.key});

  @override
  State<VendorAssignmentScreen> createState() => _VendorAssignmentScreenState();
}

class _VendorAssignmentScreenState extends State<VendorAssignmentScreen> {
  final _api = ApiClient();

  bool _isLoading = true;
  List<dynamic> _assignments = [];
  String _filter = 'pending';
  String _role = '';

  static const _filters = [
    ('pending', 'Menunggu'),
    ('confirmed', 'Dikonfirmasi'),
    ('done', 'Selesai'),
    ('rejected', 'Ditolak'),
  ];

  Color get _roleColor => AppColors.roleColor(_role);

  String _statusOf(Map<String, dynamic> a) {
    if (_role == 'pemuka_agama') return a['response'] as String? ?? 'pending';
    if (_role == 'dekor') return a['dekor_status'] as String? ?? 'pending';
    if (_role == 'konsumsi') return a['konsumsi_status'] as String? ?? 'pending';
    return a['status'] as String? ?? 'pending';
  }

  Map<String, dynamic> _orderOf(Map<String, dynamic> a) {
    if (_role == 'pemuka_agama') {
      return Map<String, dynamic>.from(a['order'] as Map? ?? {});
    }
    return a;
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _role = auth.user?['role'] as String? ?? '';
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

  Future<void> _confirm(String id) => _doAction(id, 'confirm');
  Future<void> _reject(String id, String reason) =>
      _doAction(id, 'reject', reason: reason);
  Future<void> _done(String id) => _doAction(id, 'done');

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
            const SnackBar(content: Text('Gagal memperbarui status.')));
      }
    }
  }

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
                foregroundColor: Colors.white),
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
      .where((a) =>
          _statusOf(Map<String, dynamic>.from(a)) == _filter)
      .toList();

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (_role) {
      'dekor' => 'Dekorasi',
      'konsumsi' => 'Konsumsi',
      'pemuka_agama' => 'Pemuka Agama',
      _ => 'Vendor',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Portal $roleLabel',
        accentColor: _roleColor,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: _load,
            child: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 8),
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () async {
              final nav = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              nav.pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const UnifiedLoginScreen()),
                (_) => false,
              );
            },
            child: const Icon(Icons.logout,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      label: Text(
                          '${f.$2}${count > 0 ? " ($count)" : ""}'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = f.$1),
                      selectedColor: _roleColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Tidak ada penugasan.',
                                style: TextStyle(
                                    color: AppColors.textHint)))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 24),
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

  Widget _buildCard(Map<String, dynamic> assignment) {
    final status = _statusOf(assignment);
    final order = _orderOf(assignment);
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    order['order_number'] ?? 'Penugasan',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              order['deceased_name'] ?? '-',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            if (order['service_date'] != null)
              _iconRow(Icons.calendar_today_outlined,
                  order['service_date'], AppColors.textSecondary),

            if (order['pickup_address'] != null) ...[
              const SizedBox(height: 4),
              _iconRow(Icons.location_on_outlined,
                  order['pickup_address'], AppColors.statusWarning),
            ],

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
                          side: const BorderSide(
                              color: AppColors.statusDanger),
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
                  if (isConfirmed)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _done(assignment['id']),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Selesaikan Tugas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
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
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
