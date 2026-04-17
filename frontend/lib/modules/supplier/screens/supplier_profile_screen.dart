import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<dynamic> _ratings = [];

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      try {
        final profileRes = await _api.dio.get('/supplier/profile');
        if (profileRes.data['success'] == true) {
          _profile = profileRes.data['data'] as Map<String, dynamic>?;
        }
      } catch (_) {}

      try {
        final statsRes = await _api.dio.get('/supplier/stats');
        if (statsRes.data['success'] == true) {
          _stats = statsRes.data['data'] as Map<String, dynamic>?;
        }
      } catch (_) {}

      try {
        final ratingsRes = await _api.dio.get('/supplier/ratings');
        if (ratingsRes.data['success'] == true) {
          _ratings = List<dynamic>.from(ratingsRes.data['data'] ?? []);
        }
      } catch (_) {}
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?['name'] ?? 'Supplier';
    final userEmail = context.read<AuthProvider>().user?['email'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Profil Supplier',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name
                    Center(
                      child: Column(children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: _roleColor,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(userName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        if (userEmail != null) ...[
                          const SizedBox(height: 4),
                          Text(userEmail,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                        if (_profile?['phone'] != null) ...[
                          const SizedBox(height: 2),
                          Text(_profile!['phone'],
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Verification badge
                    GlassWidget(
                      borderRadius: 16,
                      blurSigma: 16,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Icon(
                          _profile?['is_verified_supplier'] == true
                              ? Icons.verified_rounded
                              : Icons.pending_rounded,
                          color: _profile?['is_verified_supplier'] == true
                              ? AppColors.statusSuccess
                              : AppColors.statusWarning,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _profile?['is_verified_supplier'] == true
                              ? 'Supplier Terverifikasi'
                              : 'Menunggu Verifikasi',
                          style: TextStyle(
                            color: _profile?['is_verified_supplier'] == true
                                ? AppColors.statusSuccess
                                : AppColors.statusWarning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    if (_stats != null) ...[
                      Row(children: [
                        _statCard(
                            'Total Bid',
                            '${_stats!['total_bids'] ?? 0}',
                            Icons.send_rounded),
                        const SizedBox(width: 12),
                        _statCard(
                            'Win Rate',
                            '${(_stats!['win_rate'] ?? 0).toStringAsFixed(0)}%',
                            Icons.emoji_events_rounded),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _statCard(
                            'Transaksi',
                            '${_stats!['total_transactions'] ?? 0}',
                            Icons.receipt_long_rounded),
                        const SizedBox(width: 12),
                        _statCard(
                            'Rating',
                            (_stats!['avg_rating'] != null &&
                                    (_stats!['avg_rating'] as num) > 0)
                                ? (_stats!['avg_rating'] as num)
                                    .toStringAsFixed(1)
                                : '-',
                            Icons.star_rounded),
                      ]),
                      const SizedBox(height: 24),
                    ],

                    // Ratings
                    if (_ratings.isNotEmpty) ...[
                      Text('Ulasan dari Gudang',
                          style: TextStyle(
                              color: _roleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...(_ratings.take(5).map((r) => _ratingCard(r))),
                      const SizedBox(height: 24),
                    ],

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusDanger,
                          side:
                              const BorderSide(color: AppColors.statusDanger),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar'),
                        onPressed: () =>
                            context.read<AuthProvider>().logout(),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: _roleColor.withValues(alpha: 0.07),
        borderColor: _roleColor.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: _roleColor, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _ratingCard(dynamic rating) {
    final stars = (rating['rating'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.statusWarning,
                        size: 16,
                      )),
              const SizedBox(width: 8),
              Text('$stars/5',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
            if (rating['review'] != null &&
                (rating['review'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(rating['review'],
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
