import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/alarm_service.dart';
import '../../../data/services/realtime_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_catalog_screen.dart';
import 'supplier_quote_list_screen.dart';
import 'supplier_transaction_screen.dart';
import 'supplier_profile_screen.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen> {
  final ApiClient _api = ApiClient();
  final AlarmService _alarmService = AlarmService();
  late final RealTimeService _realtimeService;
  Timer? _pollTimer;

  bool _isLoading = true;
  int _openRequests = 0;
  int _totalBids = 0;
  int _bidsWon = 0;
  int _totalTransactions = 0;
  double _avgRating = 0;

  final Set<String> _knownRequestIds = {};

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _realtimeService = RealTimeService();
    _loadData(isInitial: true);
    _startPolling();
    _initPusher();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeService.unsubscribe('supplier-catalog');
    _alarmService.stopAlarm();
    super.dispose();
  }

  Future<void> _loadData({bool isInitial = false}) async {
    if (!mounted) return;
    if (isInitial) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _api.dio.get('/supplier/procurement-requests'),
        _api.dio.get('/supplier/quotes'),
        _api.dio.get('/supplier/transactions'),
      ]);

      if (!mounted) return;

      // Open procurement requests
      final requests = results[0].data['success'] == true
          ? List<dynamic>.from(results[0].data['data'] ?? [])
          : <dynamic>[];

      if (!isInitial) {
        _detectNewAndAlert(requests);
      } else {
        for (final r in requests) {
          _knownRequestIds.add(r['id'].toString());
        }
      }

      final quotes = results[1].data['success'] == true
          ? List<dynamic>.from(results[1].data['data'] ?? [])
          : <dynamic>[];

      final transactions = results[2].data['success'] == true
          ? List<dynamic>.from(results[2].data['data'] ?? [])
          : <dynamic>[];

      double rating = 0;
      try {
        final statsRes = await _api.dio.get('/supplier/stats');
        if (statsRes.data['success'] == true) {
          rating = double.tryParse(
                  statsRes.data['data']?['avg_rating']?.toString() ?? '0') ??
              0;
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _openRequests = requests.length;
        _totalBids = quotes.length;
        _bidsWon =
            quotes.where((q) => q['status'] == 'awarded').length;
        _totalTransactions = transactions.length;
        _avgRating = rating;
      });
    } catch (_) {
      // silent
    } finally {
      if (mounted && isInitial) setState(() => _isLoading = false);
    }
  }

  void _detectNewAndAlert(List<dynamic> fresh) {
    final newOnes = fresh
        .where((r) => !_knownRequestIds.contains(r['id'].toString()))
        .toList();
    if (newOnes.isEmpty) return;
    for (final r in newOnes) {
      _knownRequestIds.add(r['id'].toString());
    }
    _alarmService.playLoudAlarm();
    _showNewRequestDialog(newOnes.first);
  }

  void _showNewRequestDialog(Map<String, dynamic> request) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F3D7A), Color(0xFF4A6FA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F3D7A).withValues(alpha: 0.5),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign_rounded,
                    size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text('Permintaan Pengadaan Baru!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(request['item_name'] ?? 'Barang',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        _alarmService.stopAlarm();
                        Navigator.pop(context);
                      },
                      child: const Text('Nanti'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1F3D7A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        _alarmService.stopAlarm();
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SupplierCatalogScreen()));
                      },
                      child: const Text('Lihat Katalog',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: AppConfig.supplierPollIntervalSeconds),
      (_) => _loadData(),
    );
  }

  Future<void> _initPusher() async {
    if (AppConfig.pusherKey.isEmpty) return;
    await _realtimeService.init();
    await _realtimeService.subscribeToSupplierOrders((data) {
      if (!mounted) return;
      final id = data['id']?.toString() ?? '';
      if (id.isEmpty || _knownRequestIds.contains(id)) return;
      _knownRequestIds.add(id);
      setState(() => _openRequests++);
      _alarmService.playLoudAlarm();
      _showNewRequestDialog(Map<String, dynamic>.from(data));
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?['name'] ?? 'Supplier';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 200, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandSecondary.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _loadData(isInitial: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Supplier Portal',
                        style: TextStyle(
                            color: _roleColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Halo, $userName',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                      // Stats row
                      Row(children: [
                        _statCard('Total Bid', _totalBids.toString(),
                            Icons.send_rounded),
                        const SizedBox(width: 12),
                        _statCard('Bid Menang', _bidsWon.toString(),
                            Icons.emoji_events_rounded),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _statCard('Transaksi', _totalTransactions.toString(),
                            Icons.receipt_long_rounded),
                        const SizedBox(width: 12),
                        _statCard(
                            'Rating',
                            _avgRating > 0
                                ? _avgRating.toStringAsFixed(1)
                                : '-',
                            Icons.star_rounded),
                      ]),
                      const SizedBox(height: 28),

                      // Navigation cards
                      _navCard(
                        icon: Icons.storefront_outlined,
                        title: 'Katalog Tersedia',
                        subtitle: '$_openRequests permintaan terbuka',
                        badgeCount: _openRequests,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SupplierCatalogScreen())),
                      ),
                      const SizedBox(height: 14),
                      _navCard(
                        icon: Icons.description_outlined,
                        title: 'Penawaran Saya',
                        subtitle: '$_totalBids penawaran terkirim',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SupplierQuoteListScreen())),
                      ),
                      const SizedBox(height: 14),
                      _navCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transaksi',
                        subtitle: '$_totalTransactions transaksi',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SupplierTransactionScreen())),
                      ),
                      const SizedBox(height: 14),
                      _navCard(
                        icon: Icons.person_outline,
                        title: 'Profil',
                        subtitle: 'Kelola profil & lihat rating',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SupplierProfileScreen())),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _roleColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, color: _roleColor, size: 22)),
              if (badgeCount > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.statusDanger,
                        shape: BoxShape.circle),
                    child: Text('$badgeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right,
            color: AppColors.textHint, size: 20),
      ]),
    );
  }
}
