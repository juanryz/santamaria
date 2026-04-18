import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.39 — Purchasing input iuran bulanan membership.
/// List membership jatuh tempo + form input pembayaran.
class MembershipPaymentScreen extends StatefulWidget {
  const MembershipPaymentScreen({super.key});

  @override
  State<MembershipPaymentScreen> createState() =>
      _MembershipPaymentScreenState();
}

class _MembershipPaymentScreenState extends State<MembershipPaymentScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _dueMemberships = [];

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
      final res = await _api.dio.get('/purchasing/membership-payments/due');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _dueMemberships =
            List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat daftar iuran.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _inputPayment(Map<String, dynamic> m) async {
    final user = m['user'] as Map<String, dynamic>?;
    final fee = num.tryParse('${m['monthly_fee']}') ?? 0;
    final now = DateTime.now();

    int year = now.year;
    int month = now.month;
    String method = 'cash';
    final amountCtrl = TextEditingController(text: fee.toString());
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => AlertDialog(
          title: Text('Input Iuran — ${user?['name'] ?? '-'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: year,
                        decoration: const InputDecoration(
                            labelText: 'Tahun',
                            border: OutlineInputBorder()),
                        items: List.generate(
                          5,
                          (i) {
                            final y = now.year - 2 + i;
                            return DropdownMenuItem(value: y, child: Text('$y'));
                          },
                        ),
                        onChanged: (v) => setLocal(() => year = v ?? year),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: month,
                        decoration: const InputDecoration(
                            labelText: 'Bulan',
                            border: OutlineInputBorder()),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(DateFormat('MMMM', 'id_ID')
                                  .format(DateTime(now.year, i + 1)))),
                        ),
                        onChanged: (v) => setLocal(() => month = v ?? month),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                      labelText: 'Metode', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  ],
                  onChanged: (v) => setLocal(() => method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final res = await _api.dio.post('/purchasing/membership-payments', data: {
        'membership_id': m['id'],
        'payment_period_year': year,
        'payment_period_month': month,
        'amount': num.tryParse(amountCtrl.text) ?? 0,
        'payment_method': method,
        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Iuran tersimpan'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyimpan iuran'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Iuran Membership',
        accentColor: AppColors.rolePurchasing,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _dueMemberships.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'Tidak Ada Iuran Jatuh Tempo',
        subtitle: 'Semua member sudah bayar iuran bulan ini.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dueMemberships.length,
        itemBuilder: (c, i) =>
            _card(_dueMemberships[i] as Map<String, dynamic>),
      );

  Widget _card(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>?;
    final fee = num.tryParse('${m['monthly_fee']}') ?? 0;
    final nextDue = DateTime.tryParse(m['next_payment_due'] ?? '');
    final daysOverdue = nextDue != null
        ? DateTime.now().difference(nextDue).inDays
        : 0;
    final color = daysOverdue > 30
        ? AppColors.statusDanger
        : (daysOverdue > 0 ? AppColors.statusWarning : AppColors.statusInfo);

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.3),
      onTap: () => _inputPayment(m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${m['membership_number']} · ${user?['phone'] ?? '-'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysOverdue > 0 ? 'Telat $daysOverdue hari' : 'Jatuh tempo',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payments,
                  size: 16, color: AppColors.rolePurchasing),
              const SizedBox(width: 6),
              Text(NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0)
                  .format(fee),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rolePurchasing)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
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
