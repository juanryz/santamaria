import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';

import 'consumer_create_order_screen.dart';
import 'order_tracking_screen.dart';
import 'chat_screen.dart';
import 'my_membership_screen.dart';
import '../../auth/screens/unified_login_screen.dart';
import '../../../shared/widgets/change_password_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsumerHome extends StatefulWidget {
  const ConsumerHome({super.key});

  @override
  State<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends State<ConsumerHome> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/consumer/orders');
      if (!mounted) return;
      if (response.data['success'] == true) {
        setState(() {
          _orders = List<dynamic>.from(response.data['data'] ?? []);
        });
      }
    } catch (_) {
      // Gagal memuat — tampilkan daftar kosong
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => AppColors.statusWarning,
      'so_review' || 'admin_review' => Colors.orange,
      'approved' || 'in_progress' => AppColors.roleConsumer,
      'completed' => AppColors.statusSuccess,
      'cancelled' => AppColors.statusDanger,
      _ => AppColors.textHint,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu',
      'so_review' => 'Diproses SO',
      'admin_review' => 'Menunggu Approval',
      'approved' => 'Disetujui',
      'in_progress' => 'Sedang Berjalan',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?['name'] ?? 'Konsumen';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConsumerCreateOrderScreen()),
        ).then((created) { if (created == true) _loadOrders(); }),
        backgroundColor: AppColors.roleConsumer,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
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
                color: AppColors.roleConsumer.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
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
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    width: 140,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Halo, $userName',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const Spacer(),
                              GlassWidget(
                                borderRadius: 12,
                                blurSigma: 10,
                                tint: AppColors.glassWhite,
                                borderColor: AppColors.glassBorder,
                                padding: const EdgeInsets.all(8),
                                onTap: () async {
                                  try {
                                    await context.read<AuthProvider>().logout();
                                  } catch (_) {
                                    // Ignore API error on logout (e.g., already logged out / token expired)
                                  }
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                                      (route) => false,
                                    );
                                  }
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
                                      apiClient: _apiClient,
                                      isPin: true,
                                    ),
                                  );
                                },
                                child: const Icon(Icons.settings_outlined,
                                    color: AppColors.textSecondary, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // WhatsApp Contact Banner
                          GlassWidget(
                            borderRadius: 20,
                            blurSigma: 16,
                            tint: AppColors.statusSuccess.withValues(alpha: 0.08),
                            borderColor: AppColors.statusSuccess.withValues(alpha: 0.20),
                            padding: const EdgeInsets.all(20),
                            onTap: () async {
                              final url = Uri.parse("https://wa.me/6281127144440"); // Santa Maria Contact
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.statusSuccess.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded,
                                      color: AppColors.statusSuccess, size: 22),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Informasi Kontak WhatsApp',
                                          style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      SizedBox(height: 2),
                                      Text(
                                          'Hubungi tim Santa Maria untuk bantuan langsung',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.statusSuccess, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // AI Chat Banner
                          GlassWidget(
                            borderRadius: 20,
                            blurSigma: 16,
                            tint: AppColors.brandPrimary.withValues(alpha: 0.08),
                            borderColor: AppColors.brandPrimary.withValues(alpha: 0.20),
                            padding: const EdgeInsets.all(20),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatScreen()),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(Icons.smart_toy_outlined,
                                      color: AppColors.brandPrimary, size: 22),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Asisten AI Santa Maria',
                                          style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      SizedBox(height: 2),
                                      Text(
                                          'Ceritakan kebutuhan Anda, AI bantu isi formulir',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.brandPrimary, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // v1.39 — Kartu Anggota
                          GlassWidget(
                            borderRadius: 20,
                            blurSigma: 16,
                            tint: AppColors.brandSecondary.withValues(alpha: 0.08),
                            borderColor: AppColors.brandSecondary.withValues(alpha: 0.22),
                            padding: const EdgeInsets.all(18),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyMembershipScreen()),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.brandSecondary
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(Icons.card_membership,
                                      color: AppColors.brandSecondary, size: 22),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Keanggotaan Saya',
                                          style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      SizedBox(height: 2),
                                      Text(
                                          'Lihat status, iuran & riwayat pembayaran',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.brandSecondary, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Orders section title
                          Row(
                            children: [
                              const Text('Order Saya',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(width: 8),
                              if (_orders.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.roleConsumer.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${_orders.length}',
                                      style: const TextStyle(
                                          color: AppColors.roleConsumer,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Orders list
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_orders.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: GlassWidget(
                          borderRadius: 20,
                          blurSigma: 16,
                          tint: AppColors.glassWhite,
                          borderColor: AppColors.glassBorder,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  color: AppColors.textHint, size: 40),
                              const SizedBox(height: 12),
                              const Text('Belum ada order.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              const Text(
                                'Gunakan Asisten AI di atas untuk memulai pemesanan layanan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = _orders[index];
                            final status = order['status'] as String? ?? '';
                            final isActive =
                                status == 'approved' || status == 'in_progress';
                            final sc = _statusColor(status);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: GlassWidget(
                                borderRadius: 20,
                                blurSigma: 16,
                                tint: AppColors.glassWhite,
                                borderColor: AppColors.glassBorder,
                                padding: const EdgeInsets.all(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderTrackingScreen(
                                        orderId: order['id'] as String),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          order['order_number'] ?? 'Order',
                                          style: const TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 12,
                                              letterSpacing: 0.5),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: sc.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                                color: sc,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      order['deceased_name'] ?? '-',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order['pickup_address'] ?? '-',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: const [
                                          Icon(Icons.location_on_outlined,
                                              color: AppColors.roleConsumer,
                                              size: 14),
                                          SizedBox(width: 4),
                                          Text('Ketuk untuk pantau posisi driver',
                                              style: TextStyle(
                                                  color: AppColors.roleConsumer,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _orders.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
