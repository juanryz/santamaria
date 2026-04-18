import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.40 — Petugas Akta: Progress akta per order.
/// Stage: not_started → source_doc_received → submitted_to_dukcapil
///        → processing_dukcapil → cert_issued → waiting_payment
///        → waiting_ktp_kk_pickup → handed_to_family
class DeathCertProgressScreen extends StatefulWidget {
  final String orderId;
  const DeathCertProgressScreen({super.key, required this.orderId});

  @override
  State<DeathCertProgressScreen> createState() =>
      _DeathCertProgressScreenState();
}

class _DeathCertProgressScreenState extends State<DeathCertProgressScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _progress;
  List<dynamic> _stageLogs = [];

  static const _stages = [
    'not_started',
    'source_doc_received',
    'submitted_to_dukcapil',
    'processing_dukcapil',
    'cert_issued',
    'waiting_payment',
    'waiting_ktp_kk_pickup',
    'handed_to_family',
  ];

  static const Map<String, String> _stageLabels = {
    'not_started': 'Belum Dimulai',
    'source_doc_received': 'Surat Diterima',
    'submitted_to_dukcapil': 'Submit ke Dukcapil',
    'processing_dukcapil': 'Proses Dukcapil',
    'cert_issued': 'Akta Jadi',
    'waiting_payment': 'Tunggu Pelunasan',
    'waiting_ktp_kk_pickup': 'Tunggu KTP + KK',
    'handed_to_family': 'Diserahkan',
  };

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
      final res =
          await _api.dio.get('/petugas-akta/progress/${widget.orderId}');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>?;
        setState(() {
          _progress = data;
          _stageLogs =
              List<dynamic>.from(data?['stage_logs'] ?? []);
        });
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat progress.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = 'Progress belum dibuat atau gagal diambil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(String toStage) async {
    try {
      final res = await _api.dio.post(
          '/petugas-akta/progress/${widget.orderId}/advance',
          data: {'to_stage': toStage});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Stage diperbarui'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal memperbarui stage'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Progress Akta',
        accentColor: Color(0xFF8E44AD),
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _progress == null
                    ? _buildNotStarted()
                    : _buildProgress(),
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

  Widget _buildNotStarted() => const EmptyStateWidget(
        icon: Icons.description_outlined,
        title: 'Progress Belum Dibuat',
        subtitle:
            'Tekan "Mulai" untuk memulai pengurusan akta kematian untuk order ini.',
      );

  Widget _buildProgress() {
    final currentStage = (_progress?['current_stage'] ?? 'not_started').toString();
    final currentIdx = _stages.indexOf(currentStage);
    final days = _progress?['days_elapsed'] ?? 0;
    final deathLoc = _progress?['death_location_type'] ?? '-';
    final source = _progress?['death_certificate_source'] ?? '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassWidget(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_stageLabels[currentStage] ?? currentStage,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  GlassStatusBadge(
                    label: '$days hari',
                    color: (days as int) > 10
                        ? AppColors.statusDanger
                        : (days > 7
                            ? AppColors.statusWarning
                            : AppColors.statusInfo),
                  ),
                ],
              ),
              const Divider(height: 16),
              _infoRow('Lokasi Meninggal',
                  deathLoc == 'rumah_sakit' ? 'Rumah Sakit' : 'Rumah / Lainnya'),
              _infoRow('Sumber Surat', source.toString()),
              if (_progress?['cert_issued_at'] != null)
                _infoRow(
                    'Akta Jadi',
                    DateFormat('d MMM yyyy', 'id_ID').format(
                        DateTime.parse(_progress!['cert_issued_at']))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Timeline',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._stages.asMap().entries.map((e) =>
            _timelineItem(e.value, e.key, currentIdx)),
        const SizedBox(height: 20),
        if (currentIdx < _stages.length - 1 && currentStage != 'handed_to_family')
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                minimumSize: const Size.fromHeight(48)),
            onPressed: () => _advance(_stages[currentIdx + 1]),
            icon: const Icon(Icons.arrow_forward),
            label: Text('Lanjut ke ${_stageLabels[_stages[currentIdx + 1]]}'),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontSize: 13))),
          ],
        ),
      );

  Widget _timelineItem(String stage, int idx, int currentIdx) {
    final isDone = idx < currentIdx;
    final isCurrent = idx == currentIdx;
    final color = isDone
        ? AppColors.statusSuccess
        : (isCurrent ? AppColors.brandPrimary : AppColors.textHint);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: isDone
                ? Icon(Icons.check, size: 14, color: color)
                : (isCurrent
                    ? Icon(Icons.circle, size: 8, color: color)
                    : null),
          ),
          const SizedBox(width: 12),
          Text(_stageLabels[stage] ?? stage,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: color)),
        ],
      ),
    );
  }
}
