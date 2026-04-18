import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'stock_opname_detail_screen.dart';

/// v1.40 — Stock Opname Semester (6 bulan sekali).
/// Dipakai oleh Gudang, Super Admin (stok kantor), dan Dekor (Lafiore).
class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _sessions = [];

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
      final res = await _api.dio.get('/stock-opname/sessions');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _sessions =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat sesi opname.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startSession() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mulai Sesi Opname Semester',
      message:
          'Sistem akan membuat sesi opname untuk periode berjalan. Stok fisik harus dihitung dalam sesi ini.',
      confirmLabel: 'Mulai',
      confirmColor: AppColors.brandPrimary,
    );
    if (confirmed != true) return;

    try {
      final res = await _api.dio.post('/stock-opname/sessions/start');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final session = Map<String, dynamic>.from(res.data['data'] ?? {});
        // Langsung navigate ke detail untuk mulai counting
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => StockOpnameDetailScreen(session: session)),
        );
        if (result == true && mounted) _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal mulai sesi'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal mulai sesi opname'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Future<void> _openSession(Map<String, dynamic> session) async {
    final status = (session['status'] ?? '').toString();
    if (status == 'completed' || status == 'reviewed') {
      // Read-only view
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StockOpnameDetailScreen(session: session)),
      );
    } else {
      // Resume: server sync session state
      await _startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Stock Opname',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: _startSession,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('Mulai Semester',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _sessions.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
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

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Sesi Opname',
        subtitle:
            'Opname dilakukan 2x setahun (Januari & Juli). Tekan tombol di bawah untuk memulai.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _sessions.length,
        itemBuilder: (context, i) {
          final s = _sessions[i] as Map<String, dynamic>;
          return _sessionCard(s);
        },
      );

  Widget _sessionCard(Map<String, dynamic> s) {
    final year = s['period_year'] ?? '-';
    final sem = s['period_semester'] ?? '-';
    final status = (s['status'] ?? 'open').toString();
    final counted = s['total_items_counted'] ?? 0;
    final variance = s['total_variance_count'] ?? 0;
    final varianceAmount = num.tryParse('${s['total_variance_amount']}') ?? 0;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.roleGudang.withOpacity(0.25),
      onTap: () => _openSession(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semester $sem $year',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sem == 'H1' ? 'Januari – Juni' : 'Juli – Desember',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const Divider(height: 20),
          Row(
            children: [
              _metric('Item Terhitung', '$counted'),
              const SizedBox(width: 16),
              _metric('Selisih', '$variance'),
              const SizedBox(width: 16),
              _metric('Nilai', _rp(varianceAmount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'completed' || 'reviewed' =>
        ('Selesai', AppColors.statusSuccess),
      'in_progress' => ('Berjalan', AppColors.statusInfo),
      _ => ('Open', AppColors.textHint),
    };
    return GlassStatusBadge(label: label, color: color);
  }

  String _rp(num v) => NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(v);
}
