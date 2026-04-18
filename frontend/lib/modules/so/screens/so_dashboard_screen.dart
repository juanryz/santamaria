import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'so_order_detail_screen.dart';
import 'so_create_order_screen.dart';
import 'so_crm_screen.dart';
import '../../../shared/widgets/change_password_dialog.dart';
import '../../../shared/screens/employee_command_screen.dart';
import '../../../shared/screens/role_inventory_screen.dart';
import 'membership_list_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class SODashboardScreen extends StatefulWidget {
  const SODashboardScreen({super.key});

  @override
  State<SODashboardScreen> createState() => _SODashboardScreenState();
}

class _SODashboardScreenState extends State<SODashboardScreen> {
  late final SORepository _repo;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  static const _roleColor = AppColors.roleSO;

  @override
  void initState() {
    super.initState();
    _repo = SORepository(ApiClient());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _repo.getOrders();
      if (res.data['success'] == true) {
        setState(() => _orders = res.data['data'] as List);
      }
    } catch (e) {
      setState(() => _error = 'Gagal memuat order.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Color blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama, nomor, pesanan...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.glassWhite,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                // Stok Kantor quick access card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: GlassWidget(
                    borderRadius: 16,
                    blurSigma: 12,
                    tint: AppColors.roleSO.withValues(alpha: 0.06),
                    borderColor: AppColors.roleSO.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleInventoryScreen()),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.roleSO, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stok Kantor', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Kelola inventaris kantor SO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SOCreateOrderScreen(repo: _repo)),
        ).then((_) => _loadOrders()),
        backgroundColor: _roleColor,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('Input Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Officer',
                    style: TextStyle(
                        color: _roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('Halo, ${user?['name'] ?? 'SO'}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const Text('Segera hubungi keluarga & lakukan review.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SoCrmScreen())),
            child: const Icon(Icons.people_alt, color: AppColors.roleSO, size: 20),
          ),
          const SizedBox(width: 8),
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmployeeCommandScreen(roleColor: AppColors.roleSO))),
            child: const Icon(Icons.campaign, color: AppColors.roleSO, size: 20),
          ),
          const SizedBox(width: 8),
          // v1.39 — Membership
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MembershipListScreen())),
            child: const Icon(Icons.card_membership, color: AppColors.roleSO, size: 20),
          ),
          const SizedBox(width: 8),
          // v1.39 — My Leaves (self-service)
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyLeavesScreen())),
            child: const Icon(Icons.event_available, color: AppColors.roleSO, size: 20),
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
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                (_) => false,
              );
            },
            child: const Icon(Icons.logout,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 8),
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => ChangePasswordDialog(
                  apiClient: ApiClient(),
                  isPin: false,
                ),
              );
            },
            child: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrders, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final filteredOrders = _orders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final orderNumber = (o['order_number'] ?? '').toString().toLowerCase();
      final consumer = o['pic'] as Map<String, dynamic>?;
      final name = (o['pic_name'] ?? consumer?['name'] ?? '').toString().toLowerCase();
      final phone = (o['pic_phone'] ?? consumer?['phone'] ?? '').toString().toLowerCase();
      return orderNumber.contains(q) || name.contains(q) || phone.contains(q);
    }).toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Tidak ada order ditemukan.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final consumer = order['pic'] as Map<String, dynamic>?;
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, color: AppColors.statusDanger, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    order['order_number'] ?? '-',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(order['status'] ?? 'pending'),
                const Spacer(),
                if (timeAgo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                          color: _roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order['pic_name'] ?? consumer?['name'] ?? 'Konsumen',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            if (order['pic_phone'] != null || consumer?['phone'] != null)
              Text(order['pic_phone'] ?? consumer?['phone'] ?? '-',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            if (order['pickup_address'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.textHint, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['pickup_address'],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: consumer?['phone'] != null
                        ? () => _callPhone(consumer!['phone'])
                        : null,
                    icon: const Icon(Icons.chat, size: 16, color: Colors.green),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SOOrderDetailScreen(
                          orderId: order['id'],
                          repo: _repo,
                        ),
                      ),
                    ).then((_) => _loadOrders()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _roleColor),
                    child: Text(order['status'] == 'pending' ? 'Review' : 'Detail'),
                  ),
                ),
                if (order['status'] == 'pending') ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _confirmDelete(order['id']),
                      icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 20),
                      tooltip: 'Hapus Order',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callPhone(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp')));
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Order?'),
        content: const Text('Order yang belum dikonfirmasi ini akan dibatalkan dan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOrder(id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.statusDanger)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(String id) async {
    try {
      final res = await _repo.deleteOrder(id);
      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Order berhasil dibatalkan dan dihapus'),
            backgroundColor: AppColors.statusSuccess,
          ));
        }
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menghapus order'),
          backgroundColor: AppColors.statusDanger,
        ));
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color = AppColors.statusInfo;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending': color = AppColors.statusDanger; label = 'NEW'; break;
      case 'admin_review': color = AppColors.statusWarning; label = 'REVIEW'; break;
      case 'approved': color = AppColors.statusSuccess; label = 'APPROVED'; break;
      case 'completed': color = AppColors.statusSuccess; label = 'DONE'; break;
      case 'cancelled': color = AppColors.textHint; label = 'CANCEL'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} MENIT LALU';
    if (diff.inHours < 24) return '${diff.inHours} JAM LALU';
    return '${diff.inDays} HARI LALU';
  }
}
