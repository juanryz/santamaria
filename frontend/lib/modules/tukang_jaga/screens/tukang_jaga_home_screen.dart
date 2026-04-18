import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'tukang_jaga_shift_detail_screen.dart';
import '../../../shared/screens/my_leaves_screen.dart';

class TukangJagaHomeScreen extends StatefulWidget {
  const TukangJagaHomeScreen({super.key});

  @override
  State<TukangJagaHomeScreen> createState() => _TukangJagaHomeScreenState();
}

class _TukangJagaHomeScreenState extends State<TukangJagaHomeScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _shifts = [];

  static const _roleColor = Color(0xFF2E7D32); // deep green for tukang jaga

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
      final res = await _api.dio.get('/tukang-jaga/shifts');
      if (res.data['success'] == true) {
        setState(() => _shifts = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat shift.');
      }
    } catch (e) {
      setState(() => _error = 'Gagal memuat shift. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _shiftTypeColor(String? type) => switch (type) {
        'pagi' => Colors.orange,
        'siang' => Colors.blue,
        'malam' => Colors.purple,
        'full_day' => Colors.teal,
        _ => AppColors.brandSecondary,
      };

  Color _statusColor(String? status) => switch (status) {
        'scheduled' => Colors.grey,
        'active' => Colors.green.shade600,
        'completed' => Colors.blue,
        'missed' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String _statusLabel(String? status) => switch (status) {
        'scheduled' => 'Terjadwal',
        'active' => 'Aktif',
        'completed' => 'Selesai',
        'missed' => 'Terlewat',
        _ => status ?? '-',
      };

  bool _canCheckIn(Map<String, dynamic> shift) {
    if (shift['status'] != 'scheduled') return false;
    final startStr = shift['scheduled_start'] as String?;
    if (startStr == null) return false;
    try {
      final start = DateTime.parse(startStr);
      final now = DateTime.now();
      final diff = start.difference(now).inMinutes;
      return diff <= 15 && diff >= -5;
    } catch (_) {
      return false;
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Jadwal Shift Saya',
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
                  child: _shifts.isEmpty ? _buildEmpty() : _buildList(),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.statusDanger, size: 48),
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
                Icon(Icons.event_busy, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text('Tidak ada shift terjadwal',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
          ),
        ],
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shifts.length,
        itemBuilder: (_, i) => _buildCard(_shifts[i]),
      );

  Widget _buildCard(Map<String, dynamic> shift) {
    final status = shift['status'] as String?;
    final shiftType = shift['shift_type'] as String?;
    final sc = _statusColor(status);
    final tc = _shiftTypeColor(shiftType);
    final showCheckIn = _canCheckIn(shift);
    final showCheckOut = status == 'active';

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
            builder: (_) => TukangJagaShiftDetailScreen(
              shiftId: shift['id'].toString(),
            ),
          ),
        ).then((_) => _load()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  shift['order_code'] ?? '-',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tc.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shiftType?.toUpperCase() ?? '-',
                    style: TextStyle(color: tc, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              shift['deceased_name'] ?? '-',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Shift ${shift['shift_number'] ?? '-'}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_formatDateTime(shift['scheduled_start'])} → ${_formatDateTime(shift['scheduled_end'])}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (showCheckIn || showCheckOut) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (showCheckIn)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TukangJagaShiftDetailScreen(
                              shiftId: shift['id'].toString(),
                            ),
                          ),
                        ).then((_) => _load()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('CHECK-IN',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (showCheckOut)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TukangJagaShiftDetailScreen(
                              shiftId: shift['id'].toString(),
                            ),
                          ),
                        ).then((_) => _load()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('CHECKOUT',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
}
