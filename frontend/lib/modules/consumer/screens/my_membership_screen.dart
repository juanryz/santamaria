import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.39 — Consumer cek status membership sendiri.
/// Kartu anggota digital + riwayat iuran + countdown next payment.
class MyMembershipScreen extends StatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  State<MyMembershipScreen> createState() => _MyMembershipScreenState();
}

class _MyMembershipScreenState extends State<MyMembershipScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/consumer/me/membership');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _data =
            Map<String, dynamic>.from(res.data['data'] ?? {}));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat status keanggotaan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Keanggotaan Saya',
        accentColor: AppColors.roleConsumer,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : (_data?['is_member'] == true)
                    ? _buildMember()
                    : _buildNotMember(),
      ),
    );
  }

  Widget _buildNotMember() => const EmptyStateWidget(
        icon: Icons.card_membership_outlined,
        title: 'Belum Menjadi Anggota',
        subtitle:
            'Anda belum terdaftar sebagai anggota Santa Maria. Hubungi Customer Service untuk bergabung.',
      );

  Widget _buildMember() {
    final m = _data?['membership'] as Map<String, dynamic>? ?? {};
    final status = (m['status'] ?? '').toString();
    final qualifies = _data?['qualifies_for_member_pricing'] == true;
    final daysUntilDue = _data?['days_until_due'] as int?;
    final fee = num.tryParse('${m['monthly_fee']}') ?? 0;
    final totalPaid = num.tryParse('${m['total_paid']}') ?? 0;
    final payments = (m['payments'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(m, status, qualifies),
        const SizedBox(height: 14),
        _buildInfoRow(
          'Iuran Bulanan',
          NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
              .format(fee),
        ),
        _buildInfoRow(
          'Total Iuran Dibayar',
          NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
              .format(totalPaid),
        ),
        if (m['last_payment_date'] != null)
          _buildInfoRow(
            'Pembayaran Terakhir',
            DateFormat('d MMM yyyy', 'id_ID')
                .format(DateTime.parse(m['last_payment_date'])),
          ),
        if (m['next_payment_due'] != null)
          _buildNextDueCard(m['next_payment_due'], daysUntilDue),
        const SizedBox(height: 18),
        const Text('Riwayat Pembayaran',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Belum ada riwayat pembayaran.',
                  style: TextStyle(color: AppColors.textHint)),
            ),
          )
        else
          ...payments.map((p) => _paymentTile(p as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> m, String status, bool qualifies) {
    final number = m['membership_number']?.toString() ?? '-';
    final joined = DateTime.tryParse(m['joined_at'] ?? '');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: qualifies
              ? [AppColors.brandPrimary, AppColors.brandAccent]
              : [AppColors.textHint, AppColors.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (qualifies
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text('SANTA MARIA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ],
              ),
              _statusBadgeCard(status),
            ],
          ),
          const SizedBox(height: 24),
          Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontFamily: 'monospace')),
          const SizedBox(height: 20),
          const Text('ANGGOTA SEJAK',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          Text(
              joined != null
                  ? DateFormat('d MMMM yyyy', 'id_ID').format(joined)
                  : '-',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusBadgeCard(String status) {
    final (label, _) = switch (status) {
      'active' => ('AKTIF', Colors.green),
      'grace_period' => ('GRACE', Colors.orange),
      'inactive' => ('NONAKTIF', Colors.grey),
      'cancelled' => ('DIBATALKAN', Colors.red),
      _ => (status.toUpperCase(), Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  Widget _buildNextDueCard(String dueDate, int? daysUntilDue) {
    final dt = DateTime.tryParse(dueDate);
    if (dt == null) return const SizedBox.shrink();

    final isOverdue = daysUntilDue != null && daysUntilDue < 0;
    final isUrgent = daysUntilDue != null && daysUntilDue <= 7 && daysUntilDue >= 0;
    final color = isOverdue
        ? AppColors.statusDanger
        : (isUrgent ? AppColors.statusWarning : AppColors.statusInfo);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
              isOverdue
                  ? Icons.error_outline
                  : (isUrgent ? Icons.warning_amber : Icons.info_outline),
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue
                      ? 'Iuran Tertunggak'
                      : (isUrgent ? 'Iuran Segera Jatuh Tempo' : 'Pembayaran Berikutnya'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                Text(
                  '${DateFormat('d MMM yyyy', 'id_ID').format(dt)}' +
                      (daysUntilDue != null
                          ? (isOverdue
                              ? ' (telat ${-daysUntilDue} hari)'
                              : ' ($daysUntilDue hari lagi)')
                          : ''),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(Map<String, dynamic> p) {
    final year = p['payment_period_year'];
    final month = p['payment_period_month'];
    final amount = num.tryParse('${p['amount']}') ?? 0;
    final method = p['payment_method']?.toString() ?? '';
    final paidAt = DateTime.tryParse(p['paid_at'] ?? '');

    final periodLabel = year != null && month != null
        ? DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month))
        : '-';

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderColor: AppColors.statusSuccess.withOpacity(0.2),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.statusSuccess.withOpacity(0.15),
            radius: 16,
            child: const Icon(Icons.check_circle,
                color: AppColors.statusSuccess, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(periodLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(
                    paidAt != null
                        ? 'Dibayar ${DateFormat('d MMM yyyy', 'id_ID').format(paidAt)} · ${method.toUpperCase()}'
                        : method.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                .format(amount),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.statusSuccess),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
                  onPressed: _load, child: const Text('Coba Lagi'))),
        ],
      );
}
