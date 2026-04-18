import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.40 — Purchasing approval untuk upah HARIAN tukang foto.
/// Photographer kumpulkan sesi per hari → Purchasing finalize + bayar.
class PhotographerWageApprovalScreen extends StatefulWidget {
  const PhotographerWageApprovalScreen({super.key});

  @override
  State<PhotographerWageApprovalScreen> createState() =>
      _PhotographerWageApprovalScreenState();
}

class _PhotographerWageApprovalScreenState
    extends State<PhotographerWageApprovalScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _pending = [];

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
      final res = await _api.dio.get('/purchasing/photographer-wages/pending');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _pending =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat upah harian tukang foto.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markPaid(Map<String, dynamic> wage) async {
    final total = num.tryParse('${wage['total_wage']}') ?? 0;
    final photographer =
        wage['photographer'] as Map<String, dynamic>? ?? {};

    final ok = await ConfirmDialog.show(
      context,
      title: 'Tandai Lunas?',
      message:
          'Bayar ${_rp(total)} ke ${photographer['name'] ?? 'tukang foto'} untuk tanggal ${wage['work_date']}?',
      confirmLabel: 'Tandai Lunas',
      confirmColor: AppColors.statusSuccess,
    );
    if (!ok) return;

    try {
      final res = await _api.dio
          .put('/purchasing/photographer-wages/${wage['id']}/pay');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Pembayaran tercatat'),
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
            content: Text('Gagal menandai lunas'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _pending.fold<num>(
        0, (sum, w) => sum + (num.tryParse('${w['total_wage']}') ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Upah Harian Tukang Foto',
        accentColor: AppColors.rolePurchasing,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _pending.isEmpty
                    ? _buildEmpty()
                    : Column(
                        children: [
                          _buildSummary(totalPending),
                          Expanded(child: _buildList()),
                        ],
                      ),
      ),
    );
  }

  Widget _buildSummary(num total) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassWidget(
          padding: const EdgeInsets.all(14),
          tint: AppColors.rolePurchasing.withOpacity(0.1),
          borderColor: AppColors.rolePurchasing.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.payments, color: AppColors.rolePurchasing),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pending',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(_rp(total),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rolePurchasing)),
                  ],
                ),
              ),
              Text('${_pending.length} upah',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _pending.length,
        itemBuilder: (c, i) =>
            _wageCard(_pending[i] as Map<String, dynamic>),
      );

  Widget _wageCard(Map<String, dynamic> w) {
    final photographer = w['photographer'] as Map<String, dynamic>? ?? {};
    final date = DateTime.tryParse(w['work_date'] ?? '');
    final sessionCount = w['session_count'] ?? 0;
    final total = num.tryParse('${w['total_wage']}') ?? 0;
    final rate = num.tryParse('${w['daily_rate']}') ?? 0;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.rolePurchasing.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.rolePurchasing.withOpacity(0.15),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.rolePurchasing, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(photographer['name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                        date != null
                            ? DateFormat('EEEE, d MMM yyyy', 'id_ID')
                                .format(date)
                            : '-',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const GlassStatusBadge(
                  label: 'Siap Bayar', color: AppColors.statusInfo),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _metric('Sesi', '$sessionCount'),
              const SizedBox(width: 16),
              _metric('Rate/Hari', _rp(rate)),
              const Spacer(),
              Text(_rp(total),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rolePurchasing)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusSuccess,
              ),
              onPressed: () => _markPaid(w),
              icon: const Icon(Icons.check_circle),
              label: const Text('Tandai Lunas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary)),
        ],
      );

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

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.payments_outlined,
        title: 'Tidak Ada Upah Pending',
        subtitle:
            'Semua upah harian tukang foto sudah diproses atau belum difinalisasi.',
      );

  String _rp(num v) => NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(v);
}
