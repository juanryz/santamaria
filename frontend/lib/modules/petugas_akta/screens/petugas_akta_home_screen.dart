import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'petugas_akta_detail_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class PetugasAktaHomeScreen extends StatefulWidget {
  const PetugasAktaHomeScreen({super.key});

  @override
  State<PetugasAktaHomeScreen> createState() => _PetugasAktaHomeScreenState();
}

class _PetugasAktaHomeScreenState extends State<PetugasAktaHomeScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];

  static const _roleColor = Color(0xFF8E44AD);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/petugas-akta/orders');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _orders = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _countByStatus(String status) =>
      _orders.where((o) => o['death_cert_status'] == status).length;

  Color _statusColor(String? status) => switch (status) {
        'collecting_docs' => Colors.orange,
        'submitted_to_civil' => Colors.blue,
        'processing' => Colors.indigo,
        'completed' => Colors.teal,
        'handed_to_family' => Colors.green.shade700,
        _ => Colors.grey,
      };

  String _statusLabel(String? status) => switch (status) {
        'collecting_docs' => 'Mengumpulkan Berkas',
        'submitted_to_civil' => 'Diajukan ke Capil',
        'processing' => 'Diproses',
        'completed' => 'Selesai',
        'handed_to_family' => 'Diserahkan',
        _ => status ?? '-',
      };

  String _formatDate(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Petugas Akta Kematian',
        accentColor: _roleColor,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available, color: _roleColor),
            tooltip: 'Cuti & Izin Saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyLeavesScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty ? _buildEmpty() : _buildContent(),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusDanger, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.description_outlined,
                    size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text('Tidak ada order ditugaskan',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
          ),
        ],
      );

  Widget _buildContent() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStats(),
          const SizedBox(height: 16),
          ..._orders.map((o) => _buildCard(o as Map<String, dynamic>)),
        ],
      );

  Widget _buildStats() {
    final inProgress = _countByStatus('collecting_docs') +
        _countByStatus('submitted_to_civil') +
        _countByStatus('processing');
    final completed =
        _countByStatus('completed') + _countByStatus('handed_to_family');

    return Row(
      children: [
        _statCard('Total', _orders.length, _roleColor),
        const SizedBox(width: 8),
        _statCard('Proses', inProgress, Colors.orange),
        const SizedBox(width: 8),
        _statCard('Selesai', completed, Colors.green.shade700),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) => Expanded(
        child: GlassWidget(
          borderRadius: 16,
          blurSigma: 14,
          tint: AppColors.glassWhite,
          borderColor: color.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

  Widget _buildCard(Map<String, dynamic> order) {
    final status = order['death_cert_status'] as String?;
    final sc = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetugasAktaDetailScreen(
              orderId: order['id'].toString(),
              orderNumber: order['order_number'] ?? '-',
              deceasedName: order['deceased_name'] ?? '-',
            ),
          ),
        ).then((_) => _load()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order['order_number'] ?? '-',
                  style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: sc, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order['deceased_name'] ?? '-',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            if (order['updated_at'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.update, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Diperbarui: ${_formatDate(order['updated_at']?.toString())}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
