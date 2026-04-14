import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  int _tab = 0; // 0=Orders, 1=Pending PO, 2=Riwayat PO

  // Orders (consumer payment tracking)
  List<dynamic> _orders = [];

  // Purchase Orders
  List<dynamic> _pendingPOs = [];
  List<dynamic> _historyPOs = [];

  String? _processingId;

  static const _roleColor = AppColors.roleFinance;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Load orders
    try {
      final ordersRes = await _apiClient.dio.get('/finance/orders');
      if (!mounted) return;
      final rawData = ordersRes.data;
      List<dynamic> allOrders = [];
      if (rawData is Map && rawData['data'] != null) {
        final d = rawData['data'];
        if (d is List) {
          allOrders = d;
        } else if (d is Map && d['data'] != null) {
          allOrders = List<dynamic>.from(d['data']);
        }
      }
      if (mounted) setState(() => _orders = allOrders);
    } catch (_) {
      // orders load failed silently — PO still loads
    }

    // Load purchase orders
    try {
      final poRes = await _apiClient.dio.get('/finance/purchase-orders');
      if (!mounted) return;
      if (poRes.data['success'] == true) {
        final all = List<dynamic>.from(poRes.data['data'] ?? []);
        if (mounted) {
          setState(() {
            _pendingPOs = all
                .where((po) => po['status'] == 'pending_finance')
                .toList();
            _historyPOs = all
                .where((po) => po['status'] != 'pending_finance')
                .toList();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat data PO.')));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approvePayment(String orderId, String orderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran?'),
        content: Text('Tandai payment order $orderNumber sebagai LUNAS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi Lunas'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processingId = orderId);
    try {
      final res = await _apiClient.dio.put(
        '/finance/orders/$orderId/payment/verify',
        data: {},
      );
      if (!mounted) return;
      if (res.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran dikonfirmasi lunas.')),
        );
        await _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengonfirmasi pembayaran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _viewPaymentProof(String orderId, String orderNumber) async {
    try {
      final res = await _apiClient.dio.get(
        '/finance/orders/$orderId/payment-proof',
      );
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>?;
      final proofUrl = data?['payment_proof_url'] as String?;
      final uploadedAt = data?['payment_proof_uploaded_at'] as String?;
      final finalPrice = data?['final_price'];

      if (proofUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti payment belum diupload.')),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bukti Payment — $orderNumber',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textHint),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                if (finalPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Nilai: ${_currency.format(double.tryParse(finalPrice.toString()) ?? 0)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (uploadedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Diupload: ${_formatDate(uploadedAt)}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    proofUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    errorBuilder: (_, _, err) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textHint,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar.',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat bukti payment.')),
        );
      }
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _rejectPayment(String orderId, String orderNumber) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Bukti Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tolak bukti payment untuk order $orderNumber?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan (wajib)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processingId = orderId);
    try {
      await _apiClient.dio.put(
        '/finance/orders/$orderId/payment/reject',
        data: {'reason': reasonCtrl.text.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti ditolak. Konsumen diminta upload ulang.'),
        ),
      );
      await _loadData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menolak bukti payment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _approvePO(String poId, String itemName) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui PO?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setujui Purchase Order untuk $itemName?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _processingId = poId);
    try {
      final response = await _apiClient.dio.put(
        '/finance/purchase-orders/$poId/approve',
        data: {'notes': notesController.text.trim()},
      );
      if (!mounted) return;
      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PO berhasil disetujui. Gudang telah dinotifikasi.'),
          ),
        );
        await _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menyetujui PO.')));
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectPO(String poId, String itemName) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak PO?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak Purchase Order untuk $itemName?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan (wajib)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            onPressed: () {
              if (notesController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _processingId = poId);
    try {
      final response = await _apiClient.dio.put(
        '/finance/purchase-orders/$poId/reject',
        data: {'notes': notesController.text.trim()},
      );
      if (!mounted) return;
      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PO ditolak. Gudang telah dinotifikasi.'),
          ),
        );
        await _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menolak PO.')));
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  // ─── Status helpers ────────────────────────────────────────────
  Color _poStatusColor(String s) => switch (s) {
    'approved_finance' => AppColors.statusSuccess,
    'rejected' => AppColors.statusDanger,
    'pending_finance' => AppColors.statusWarning,
    _ => AppColors.textHint,
  };

  String _poStatusLabel(String s) => switch (s) {
    'approved_finance' => 'Disetujui',
    'rejected' => 'Ditolak',
    'pending_finance' => 'Menunggu Review',
    _ => s,
  };

  Color _paymentStatusColor(String s) => switch (s) {
    'proof_uploaded' => AppColors.statusWarning,
    'paid' => AppColors.statusSuccess,
    'proof_rejected' => AppColors.statusDanger,
    'unpaid' => AppColors.textHint,
    _ => AppColors.textHint,
  };

  String _paymentStatusLabel(String s) => switch (s) {
    'proof_uploaded' => 'Bukti Diupload',
    'paid' => 'Lunas ✓',
    'proof_rejected' => 'Ditolak',
    'unpaid' => 'Belum Bayar',
    _ => s,
  };

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?['name'] ?? 'Finance';

    final proofUploaded = _orders
        .where((o) => o['payment_status'] == 'proof_uploaded')
        .length;
    final pendingPOCount = _pendingPOs.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Finance Portal',
                              style: TextStyle(
                                color: _roleColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Halo, $userName',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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
                            final nav = Navigator.of(context);
                            await context.read<AuthProvider>().logout();
                            if (!mounted) return;
                            nav.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const UnifiedLoginScreen(),
                              ),
                              (_) => false,
                            );
                          },
                          child: const Icon(
                            Icons.logout,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab selector (3 tabs)
                    GlassWidget(
                      borderRadius: 50,
                      blurSigma: 10,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _pillBtn('Payment Order', 0, badge: proofUploaded),
                          _pillBtn('Perlu Review PO', 1, badge: pendingPOCount),
                          _pillBtn('Riwayat PO', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_tab == 0)
                      _buildOrdersTab()
                    else if (_tab == 1)
                      _buildPendingPOs()
                    else
                      _buildHistoryPOs(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ORDERS TAB ────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.textHint),
            SizedBox(width: 12),
            Text(
              'Tidak ada order dengan bukti payment.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _orders
          .map((order) => _buildOrderCard(Map<String, dynamic>.from(order)))
          .toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String? ?? '';
    final orderNumber = order['order_number'] as String? ?? '-';
    final paymentStatus = order['payment_status'] as String? ?? 'unpaid';
    final finalPrice = order['final_price'];
    final pkg = order['package'] as Map<String, dynamic>?;
    final soUser = order['so_user'] as Map<String, dynamic>?;
    final picName = order['pic_name'] as String? ?? '-';
    final sc = _paymentStatusColor(paymentStatus);
    final isProofUploaded = paymentStatus == 'proof_uploaded';
    final isProcessing = _processingId == orderId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: isProofUploaded
            ? AppColors.statusWarning.withValues(alpha: 0.04)
            : AppColors.glassWhite,
        borderColor: isProofUploaded
            ? AppColors.statusWarning.withValues(alpha: 0.4)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                if (isProofUploaded)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.notification_important_rounded,
                      color: AppColors.statusWarning,
                      size: 18,
                    ),
                  ),
                Expanded(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _paymentStatusLabel(paymentStatus),
                    style: TextStyle(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('PIC', picName),
            if (pkg != null) _infoRow('Paket', pkg['name'] ?? '-'),
            if (soUser != null) _infoRow('SO', soUser['name'] ?? '-'),
            if (finalPrice != null)
              _infoRow(
                'Nilai',
                _currency.format(double.tryParse(finalPrice.toString()) ?? 0),
              ),
            // Lihat bukti — tampil jika payment_status bukan unpaid
            if (paymentStatus != 'unpaid') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewPaymentProof(orderId, orderNumber),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _roleColor,
                    side: const BorderSide(color: AppColors.roleFinance),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text(
                    'Lihat Bukti Payment',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
            // Action buttons for proof_uploaded
            if (isProofUploaded) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _rejectPayment(orderId, orderNumber),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(color: AppColors.statusDanger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _approvePayment(orderId, orderNumber),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text(
                        'Konfirmasi Lunas',
                        style: TextStyle(fontSize: 12),
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

  // ─── PO Tabs ───────────────────────────────────────────────────

  Widget _buildPendingPOs() {
    if (_pendingPOs.isEmpty) {
      return GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.textHint),
            SizedBox(width: 12),
            Text(
              'Tidak ada PO untuk ditampilkan.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _pendingPOs
          .map(
            (po) =>
                _buildPOCard(Map<String, dynamic>.from(po), isPending: true),
          )
          .toList(),
    );
  }

  Widget _buildHistoryPOs() {
    if (_historyPOs.isEmpty) {
      return GlassWidget(
        borderRadius: 16,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(24),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.textHint),
            SizedBox(width: 12),
            Text(
              'Tidak ada riwayat PO.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _historyPOs
          .map((po) => _buildPOCard(Map<String, dynamic>.from(po)))
          .toList(),
    );
  }

  Widget _buildPOCard(Map<String, dynamic> po, {bool isPending = false}) {
    final poId = po['id'] as String? ?? '';
    final itemName = po['item_name'] as String? ?? 'Item';
    final status = po['status'] as String? ?? '';
    final supplierName = po['supplier_name'] as String?;
    final financeNotes = po['finance_notes'] as String?;
    final isProcessing = _processingId == poId;
    final sc = _poStatusColor(status);

    final quotes = List<dynamic>.from(po['supplier_quotes'] ?? []);
    final acceptedQuote = quotes.cast<Map<String, dynamic>?>().firstWhere(
      (q) => q?['status'] == 'accepted',
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassWidget(
        borderRadius: 20,
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
                    itemName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _poStatusLabel(status),
                    style: TextStyle(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('Qty', '${po['quantity']} ${po['unit']}'),
            _infoRow('Harga Estimasi', 'Rp ${po['proposed_price']}'),
            if (po['market_price'] != null)
              _infoRow('Harga Pasar (AI)', 'Rp ${po['market_price']}'),
            if (acceptedQuote != null) ...[
              const Divider(height: 20),
              _infoRow(
                'Supplier',
                supplierName ?? acceptedQuote['supplier']?['name'] ?? '-',
              ),
              _infoRow('Harga Penawaran', 'Rp ${acceptedQuote['quote_price']}'),
            ],
            if (po['ai_analysis'] != null) ...[
              const Divider(height: 20),
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.statusWarning,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Analisis AI',
                    style: TextStyle(
                      color: AppColors.statusWarning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                po['ai_analysis'] as String,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (financeNotes != null && financeNotes.isNotEmpty) ...[
              const Divider(height: 20),
              _infoRow('Catatan Finance', financeNotes),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _rejectPO(poId, itemName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: const BorderSide(color: AppColors.statusDanger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _approvePO(poId, itemName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text(
                        'Setujui',
                        style: TextStyle(fontSize: 13),
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

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _pillBtn(String label, int index, {int badge = 0}) {
    final isSelected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _roleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 4),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.statusDanger,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
