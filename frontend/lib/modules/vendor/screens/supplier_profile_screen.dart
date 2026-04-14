import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  final SupplierRepository _repository = SupplierRepository(ApiClient());

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  int _totalQuotes = 0;
  int _acceptedQuotes = 0;

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getProfile(),
        _repository.getSupplierQuotes(),
      ]);

      if (!mounted) return;

      if (results[0].data['success'] == true) {
        _profile = results[0].data['data']['user'] as Map<String, dynamic>?;
      }

      if (results[1].data['success'] == true) {
        final quotes = List<dynamic>.from(results[1].data['data'] ?? []);
        _totalQuotes = quotes.length;
        _acceptedQuotes =
            quotes.where((q) => q['status'] == 'accepted').length;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat profil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _winRate =>
      _totalQuotes == 0 ? 0 : _acceptedQuotes / _totalQuotes * 100;

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?['name'] ?? 'Supplier';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Profil Supplier',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
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
                        if (_profile?['email'] != null) ...[
                          const SizedBox(height: 4),
                          Text(_profile!['email'],
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats row
                  Row(
                    children: [
                      _statCard('Total Penawaran',
                          _totalQuotes.toString(), Icons.send_rounded),
                      const SizedBox(width: 12),
                      _statCard('Diterima',
                          _acceptedQuotes.toString(),
                          Icons.check_circle_outline),
                      const SizedBox(width: 12),
                      _statCard('Win Rate',
                          '${_winRate.toStringAsFixed(0)}%',
                          Icons.emoji_events_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Verification badge
                  GlassWidget(
                    borderRadius: 16,
                    blurSigma: 16,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(color: AppColors.statusDanger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
