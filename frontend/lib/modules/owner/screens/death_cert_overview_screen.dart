import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../petugas_akta/screens/death_cert_progress_screen.dart';

/// v1.40 — Owner/HRD/Super Admin monitoring akta progress.
/// Overview semua akta yang belum selesai + highlight overdue > 14 hari.
class DeathCertOverviewScreen extends StatefulWidget {
  const DeathCertOverviewScreen({super.key});

  @override
  State<DeathCertOverviewScreen> createState() =>
      _DeathCertOverviewScreenState();
}

class _DeathCertOverviewScreenState extends State<DeathCertOverviewScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  String _filter = 'all'; // all, overdue, warning, on_track

  static const _maxDays = 14;
  static const _warnDays = 10;

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
      final res = await _api.dio.get('/petugas-akta/progress');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _items =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat overview akta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _daysElapsed(Map<String, dynamic> item) {
    final started = DateTime.tryParse(item['started_at'] ?? '');
    if (started == null) return 0;
    return DateTime.now().difference(started).inDays;
  }

  List<dynamic> get _filtered {
    return switch (_filter) {
      'overdue' => _items.where((i) => _daysElapsed(i) > _maxDays).toList(),
      'warning' => _items.where((i) {
          final d = _daysElapsed(i);
          return d >= _warnDays && d <= _maxDays;
        }).toList(),
      'on_track' => _items.where((i) => _daysElapsed(i) < _warnDays).toList(),
      _ => _items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _items.where((i) => _daysElapsed(i) > _maxDays).length;
    final warning = _items.where((i) {
      final d = _daysElapsed(i);
      return d >= _warnDays && d <= _maxDays;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Monitoring Akta Kematian',
        accentColor: Color(0xFF8E44AD),
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _buildSummary(overdue, warning),
                      _buildFilterChips(),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.folder_outlined,
                                title: 'Tidak Ada Data',
                                subtitle:
                                    'Semua akta sudah selesai atau tidak ada di kategori ini.',
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filtered.length,
                                itemBuilder: (c, i) => _progressCard(
                                    _filtered[i] as Map<String, dynamic>),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummary(int overdue, int warning) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusDanger.withOpacity(0.1),
                borderColor: AppColors.statusDanger.withOpacity(0.3),
                child: Column(
                  children: [
                    Text('$overdue',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusDanger)),
                    const Text('Overdue > 14 hari',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusWarning.withOpacity(0.15),
                borderColor: AppColors.statusWarning.withOpacity(0.3),
                child: Column(
                  children: [
                    Text('$warning',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusWarning)),
                    const Text('Mendekati Deadline',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusSuccess.withOpacity(0.1),
                borderColor: AppColors.statusSuccess.withOpacity(0.3),
                child: Column(
                  children: [
                    Text('${_items.length - overdue - warning}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusSuccess)),
                    const Text('On Track',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChips() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          spacing: 8,
          children: [
            _chip('Semua', 'all'),
            _chip('Overdue', 'overdue'),
            _chip('Mendekati', 'warning'),
            _chip('On Track', 'on_track'),
          ],
        ),
      );

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
      labelStyle: TextStyle(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
    );
  }

  Widget _progressCard(Map<String, dynamic> p) {
    final order = p['order'] as Map<String, dynamic>? ?? {};
    final petugas = p['petugas_akta'] as Map<String, dynamic>? ?? {};
    final days = _daysElapsed(p);
    final stage = (p['current_stage'] ?? 'not_started').toString();
    final color = days > _maxDays
        ? AppColors.statusDanger
        : (days >= _warnDays
            ? AppColors.statusWarning
            : AppColors.statusSuccess);

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.3),
      onTap: () {
        final orderId = p['order_id'];
        if (orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DeathCertProgressScreen(orderId: orderId.toString()),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['order_number'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(order['deceased_name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GlassStatusBadge(label: '$days hari', color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag,
                  size: 14, color: AppColors.brandPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_stageLabel(stage),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(petugas['name'] ?? 'Belum di-assign',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  String _stageLabel(String s) => switch (s) {
        'not_started' => 'Belum Dimulai',
        'source_doc_received' => 'Surat Diterima',
        'submitted_to_dukcapil' => 'Di Dukcapil',
        'processing_dukcapil' => 'Proses Dukcapil',
        'cert_issued' => 'Akta Jadi',
        'waiting_payment' => 'Tunggu Pelunasan',
        'waiting_ktp_kk_pickup' => 'Tunggu KTP+KK',
        'handed_to_family' => 'Diserahkan',
        _ => s,
      };

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
