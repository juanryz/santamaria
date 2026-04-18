import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.40 — Upah tukang foto PER HARI (banyak sesi per hari).
/// Tukang foto lihat rincian upah harian + status (draft/finalized/paid).
class PhotographerDailyWagesScreen extends StatefulWidget {
  const PhotographerDailyWagesScreen({super.key});

  @override
  State<PhotographerDailyWagesScreen> createState() =>
      _PhotographerDailyWagesScreenState();
}

class _PhotographerDailyWagesScreenState
    extends State<PhotographerDailyWagesScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _wages = [];
  static const _roleColor = Color(0xFF8E44AD);

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
      final res = await _api.dio.get('/tukang-foto/daily-wages/me');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() =>
            _wages = List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat upah harian.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtRp(num? v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Upah Harian',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _wages.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.error_outline, size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
                onPressed: _load, child: const Text('Coba Lagi')),
          ),
        ],
      );

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.payments_outlined,
        title: 'Belum Ada Upah Harian',
        subtitle: 'Upah akan muncul otomatis setelah Anda mengambil order.',
      );

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _wages.length,
      itemBuilder: (context, i) {
        final w = _wages[i] as Map<String, dynamic>;
        final date = DateTime.tryParse(w['work_date'] ?? '');
        final dateLabel = date != null
            ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date)
            : (w['work_date'] ?? '-');
        final status = (w['status'] ?? 'draft').toString();
        final sessionCount = w['session_count'] ?? 0;
        final orderIds = (w['order_ids'] as List?) ?? [];
        final total = num.tryParse('${w['total_wage']}') ?? 0;
        final rate = num.tryParse('${w['daily_rate']}') ?? 0;

        return GlassWidget(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          borderColor: _roleColor.withOpacity(0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(dateLabel,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metric('Sesi', '$sessionCount'),
                  const SizedBox(width: 20),
                  _metric('Rate/Hari', _fmtRp(rate)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Upah',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text(_fmtRp(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              if (orderIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${orderIds.length} order hari ini',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      );

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'paid' => ('Lunas', AppColors.statusSuccess),
      'finalized' => ('Finalisasi', AppColors.statusInfo),
      _ => ('Draft', AppColors.textHint),
    };
    return GlassStatusBadge(label: label, color: color);
  }
}
