import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_catalog_screen.dart';
import 'supplier_profile_screen.dart';
import 'supplier_quote_detail_screen.dart';
import 'supplier_quote_form_screen.dart';
import 'supplier_transaction_screen.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  late final SupplierRepository _repository;
  late final RealTimeService _realtimeService;
  final AlarmService _alarmService = AlarmService();

  bool _isLoading = true;
  int _selectedTabIndex = 0;
  List<dynamic> _orders = [];
  List<dynamic> _quotes = [];

  final Set<String> _knownOrderIds = {};
  Timer? _pollTimer;

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _repository = SupplierRepository(ApiClient());
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
        _repository.getAvailablePurchaseOrders(),
        _repository.getSupplierQuotes(),
      ]);

      if (!mounted) return;

      final newOrders = results[0].data['success'] == true
          ? List<dynamic>.from(results[0].data['data'] ?? [])
          : <dynamic>[];

      if (results[1].data['success'] == true) {
        _quotes = List<dynamic>.from(results[1].data['data'] ?? []);
      }

      if (!isInitial) {
        _detectNewOrdersAndAlert(newOrders);
      }

      setState(() {
        _orders = newOrders;
        if (isInitial) {
          for (final o in _orders) {
            _knownOrderIds.add(o['id'].toString());
          }
        }
      });
    } catch (_) {
      if (mounted && isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data supplier.')),
        );
      }
    } finally {
      if (mounted && isInitial) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _detectNewOrdersAndAlert(List<dynamic> freshOrders) {
    final newOnes = freshOrders
        .where((o) => !_knownOrderIds.contains(o['id'].toString()))
        .toList();

    if (newOnes.isEmpty) return;

    for (final o in newOnes) {
      _knownOrderIds.add(o['id'].toString());
    }

    _triggerAlert(newOnes);
  }

  void _triggerAlert(List<dynamic> newOrders) {
    _alarmService.playLoudAlarm();
    _showNewOrderDialog(newOrders);
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
      final orderId = data['id']?.toString() ?? '';
      if (orderId.isEmpty || _knownOrderIds.contains(orderId)) return;

      _knownOrderIds.add(orderId);
      setState(() => _orders = [data, ..._orders]);
      _triggerAlert([data]);
    });
  }

  Future<void> _openQuoteForm(Map<String, dynamic> order) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierQuoteFormScreen(purchaseOrder: order),
      ),
    );
    if (submitted == true && mounted) {
      await _loadData();
    }
  }

  void _showNewOrderDialog(List<dynamic> newOrders) {
    if (!mounted) return;

    final firstOrder = newOrders.first;
    final itemName = firstOrder['item_name'] ?? 'Barang';
    final qty = firstOrder['quantity'];
    final unit = firstOrder['unit'];
    final extra =
        newOrders.length > 1 ? ' (+${newOrders.length - 1} lainnya)' : '';

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
                colors: [Color(0xFF6A0572), Color(0xFFB5179E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB5179E).withValues(alpha: 0.7),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: const Icon(Icons.campaign_rounded,
                      size: 72, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠ PERMINTAAN BARU!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '$itemName$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (qty != null && unit != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Qty: $qty $unit',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Purchasing membutuhkan penawaran segera.\nAjukan harga terbaik Anda sekarang!',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _alarmService.stopAlarm();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Nanti'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A0572),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _alarmService.stopAlarm();
                          Navigator.of(context).pop();
                          setState(() => _selectedTabIndex = 0);
                          _openQuoteForm(
                              Map<String, dynamic>.from(firstOrder));
                        },
                        child: const Text('Ajukan Sekarang',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'accepted' => AppColors.statusSuccess,
        'rejected' => AppColors.statusDanger,
        'pending' => AppColors.statusWarning,
        _ => AppColors.textSecondary,
      };

  String _statusLabel(String status) => switch (status) {
        'accepted' => 'Diterima',
        'rejected' => 'Ditolak',
        'pending' => 'Menunggu',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?['name'] ?? 'Supplier';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                      const Spacer(),
                      GlassWidget(
                        borderRadius: 12,
                        blurSigma: 10,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SupplierCatalogScreen()),
                        ),
                        child: const Icon(Icons.storefront_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      GlassWidget(
                        borderRadius: 12,
                        blurSigma: 10,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SupplierTransactionScreen()),
                        ),
                        child: const Icon(Icons.receipt_long_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      GlassWidget(
                        borderRadius: 12,
                        blurSigma: 10,
                        tint: AppColors.glassWhite,
                        borderColor: AppColors.glassBorder,
                        padding: const EdgeInsets.all(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SupplierProfileScreen()),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pill tab selector
                  GlassWidget(
                    borderRadius: 50,
                    blurSigma: 10,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _pillBtn('Permintaan', 0),
                        _pillBtn('Penawaran Saya', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 24),
                  ],

                  if (!_isLoading) ...[
                    GlassWidget(
                      borderRadius: 16,
                      blurSigma: 16,
                      tint: _roleColor.withValues(alpha: 0.06),
                      borderColor: _roleColor.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTabIndex == 0
                                ? 'Total Permintaan: ${_orders.length}'
                                : 'Total Penawaran: ${_quotes.length}',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTabIndex == 0
                                ? 'Lihat semua permintaan terbaru dari Purchasing.'
                                : 'Lihat status dan detail penawaran yang sudah Anda kirim.',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_selectedTabIndex == 0) ...[
                      if (_orders.isEmpty) ...[
                        const Text('Belum ada permintaan barang terbaru.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        const SizedBox(height: 16),
                      ],
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: GlassWidget(
                              borderRadius: 20,
                              blurSigma: 16,
                              tint: AppColors.glassWhite,
                              borderColor: AppColors.glassBorder,
                              padding: const EdgeInsets.all(16),
                              onTap: () => _openQuoteForm(
                                  Map<String, dynamic>.from(order)),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(order['item_name'] ?? 'Barang',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Qty: ${order['quantity']} ${order['unit']}',
                                      style: const TextStyle(
                                          color:
                                              AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Harga estimasi: ${order['proposed_price']}',
                                      style: const TextStyle(
                                          color:
                                              AppColors.textSecondary)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.send,
                                          color: _roleColor, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                          'Ketuk untuk mengirim penawaran',
                                          style: TextStyle(
                                              color: _roleColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      if (_quotes.isEmpty) ...[
                        const Text('Belum ada penawaran terkirim.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        const SizedBox(height: 16),
                      ],
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          final purchaseOrder =
                              quote['purchase_order'] as Map? ?? {};
                          final status =
                              quote['status'] as String? ?? 'pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: GlassWidget(
                              borderRadius: 20,
                              blurSigma: 16,
                              tint: _statusColor(status)
                                  .withValues(alpha: 0.05),
                              borderColor: _statusColor(status)
                                  .withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SupplierQuoteDetailScreen(
                                            quote: Map<String,
                                                dynamic>.from(quote)),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      purchaseOrder['item_name'] ??
                                          'Penawaran',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Quote: ${quote['quote_price']}',
                                      style: const TextStyle(
                                          color:
                                              AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Status: ',
                                          style: const TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 12)),
                                      Text(_statusLabel(status),
                                          style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.chevron_right,
                                          color: AppColors.textHint,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      const Text(
                                          'Ketuk untuk detail penawaran',
                                          style: TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, int index) {
    final isSelected = index == _selectedTabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _roleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
