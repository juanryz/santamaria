import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.40 — Finance/Purchasing: reminder pembayaran consumer H+4..H+10.
///
/// Aturan:
/// - Deadline bayar: H+3 setelah order completed
/// - Toleransi: H+4..H+10 (reminder harian via WA)
/// - H+11+: escalation critical
class PaymentReminderScreen extends StatefulWidget {
  const PaymentReminderScreen({super.key});

  @override
  State<PaymentReminderScreen> createState() => _PaymentReminderScreenState();
}

class _PaymentReminderScreenState extends State<PaymentReminderScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _overdueOrders = [];

  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOverdue();
  }

  Future<void> _loadOverdue() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _apiClient.dio.get('/finance/payment-reminders/overdue');
      if (!mounted) return;
      final data = res.data['data'];
      setState(() {
        _overdueOrders = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar overdue.';
          _isLoading = false;
        });
      }
    }
  }

  Color _levelColor(String level) {
    return switch (level) {
      'critical' => AppColors.statusDanger,
      'high' => AppColors.statusWarning,
      'normal' => AppColors.statusInfo,
      _ => AppColors.textHint,
    };
  }

  String _levelLabel(String level) {
    return switch (level) {
      'critical' => 'CRITICAL',
      'high' => 'HIGH',
      'normal' => 'REMINDER',
      _ => level.toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _overdueOrders.where((o) => o['escalation_level'] == 'critical').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reminder Pembayaran',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadOverdue,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOverdue,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _overdueOrders.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _buildSummary(criticalCount),
                          const SizedBox(height: 16),
                          _buildLegend(),
                          const SizedBox(height: 12),
                          ..._overdueOrders.map((o) => _buildOrderCard(o)),
                        ],
                      ),
      ),
    );
  }

  Widget _buildSummary(int criticalCount) {
    final color = criticalCount > 0 ? AppColors.statusDanger : AppColors.statusWarning;
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.schedule_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_overdueOrders.length} order overdue',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  criticalCount > 0
                      ? '$criticalCount critical (> H+10) — butuh eskalasi'
                      : 'Semua dalam toleransi H+4..H+10',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(AppColors.statusInfo, 'H+4..H+7'),
        const SizedBox(width: 14),
        _legendDot(AppColors.statusWarning, 'H+8..H+10'),
        const SizedBox(width: 14),
        _legendDot(AppColors.statusDanger, '> H+10'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final name = o['consumer_name'] as String? ?? '-';
    final code = o['order_number'] as String? ?? '-';
    final phone = o['consumer_phone'] as String? ?? '';
    final days = (o['days_overdue'] as int?) ?? 0;
    final level = o['escalation_level'] as String? ?? 'normal';
    final reminderCount = (o['reminder_count'] as int?) ?? 0;
    final color = _levelColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: color.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _levelLabel(level),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Text('•', style: TextStyle(color: AppColors.textHint)),
                const SizedBox(width: 10),
                Text(
                  'H+$days',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (reminderCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$reminderCount× reminder',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openOrderDetail(o),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('Lihat Riwayat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _logReminderDialog(o),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Catat Kirim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrderDetail(dynamic o) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderReminderHistorySheet(
        orderId: o['order_id'] as String,
        orderNumber: o['order_number'] as String? ?? '-',
        consumerName: o['consumer_name'] as String? ?? '-',
      ),
    );
  }

  Future<void> _logReminderDialog(dynamic o) async {
    final daysOverdue = (o['days_overdue'] as int?) ?? 0;
    final reminderDay = (3 + daysOverdue).clamp(4, 10); // H+4..H+10
    final phone = o['consumer_phone'] as String? ?? '';
    String sentVia = 'whatsapp';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Catat Reminder H+$reminderDay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${o['order_number']}'),
              Text('Consumer: ${o['consumer_name']}'),
              Text('Phone: $phone'),
              const SizedBox(height: 16),
              const Text('Metode:', style: TextStyle(fontWeight: FontWeight.w600)),
              ...['whatsapp', 'phone', 'sms', 'app_notif'].map((m) => RadioListTile<String>(
                dense: true,
                title: Text(m),
                value: m,
                groupValue: sentVia,
                onChanged: (v) => setDialog(() => sentVia = v ?? 'whatsapp'),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Catat'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiClient.dio.post(
        '/finance/payment-reminders/orders/${o['order_id']}',
        data: {
          'reminder_day': reminderDay,
          'sent_via': sentVia,
          'recipient_phone': phone,
          'template_used': 'PAYMENT_REMINDER_CONSUMER',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder tercatat'), backgroundColor: AppColors.statusSuccess),
      );
      _loadOverdue();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusDanger),
              const SizedBox(height: 12),
              Text(_error ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadOverdue, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: AppColors.statusSuccess),
              SizedBox(height: 12),
              Text('Tidak ada order overdue 🎉', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 4),
              Text('Semua payment dalam deadline.', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal bottom sheet: riwayat reminder untuk 1 order.
class _OrderReminderHistorySheet extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String consumerName;

  const _OrderReminderHistorySheet({
    required this.orderId,
    required this.orderNumber,
    required this.consumerName,
  });

  @override
  State<_OrderReminderHistorySheet> createState() => _OrderReminderHistorySheetState();
}

class _OrderReminderHistorySheetState extends State<_OrderReminderHistorySheet> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _apiClient.dio.get('/finance/payment-reminders/orders/${widget.orderId}');
      if (!mounted) return;
      final data = res.data['data'];
      setState(() {
        _reminders = data is List ? data : [];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Reminder',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.orderNumber} — ${widget.consumerName}',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          Flexible(
            child: _isLoading
                ? const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
                : _reminders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Belum ada reminder terkirim.',
                            style: TextStyle(color: AppColors.textHint)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _reminders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final r = _reminders[i];
                          final day = r['reminder_day'] as int? ?? 0;
                          final via = r['sent_via'] as String? ?? '-';
                          final date = r['reminder_date'] as String? ?? '';
                          final responded = r['consumer_responded'] == true;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.roleFinance.withValues(alpha: 0.15),
                              child: Text('H+$day',
                                  style: const TextStyle(
                                      color: AppColors.roleFinance,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text('$via — $date'),
                            subtitle: responded
                                ? const Text('Consumer respond ✓',
                                    style: TextStyle(color: AppColors.statusSuccess))
                                : const Text('Belum ada respond'),
                            trailing: responded
                                ? const Icon(Icons.check_circle, color: AppColors.statusSuccess)
                                : const Icon(Icons.hourglass_empty, color: AppColors.textHint),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
