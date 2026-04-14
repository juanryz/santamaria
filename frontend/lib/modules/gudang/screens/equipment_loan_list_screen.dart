import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import 'equipment_loan_form_screen.dart';

class EquipmentLoanListScreen extends StatefulWidget {
  const EquipmentLoanListScreen({super.key});

  @override
  State<EquipmentLoanListScreen> createState() =>
      _EquipmentLoanListScreenState();
}

class _EquipmentLoanListScreenState extends State<EquipmentLoanListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _loans = [];
  String _filter = 'semua'; // semua, aktif, dikembalikan, terlambat

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/gudang/equipment-loans');
      if (res.data['success'] == true) {
        _loans = List<dynamic>.from(res.data['data'] ?? []);
      } else if (res.data['data'] != null) {
        _loans = List<dynamic>.from(res.data['data']);
      } else if (res.data is List) {
        _loans = List<dynamic>.from(res.data);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _loanStatus(Map<String, dynamic> loan) {
    final status = loan['status']?.toString().toLowerCase() ?? '';
    if (status == 'returned' || status == 'dikembalikan') return 'dikembalikan';

    // Check overdue based on tgl_peringatan
    final tglStr = loan['tgl_peringatan']?.toString();
    if (tglStr != null && tglStr.isNotEmpty) {
      try {
        final tgl = DateTime.parse(tglStr);
        if (tgl.isBefore(DateTime.now()) &&
            status != 'returned' &&
            status != 'dikembalikan') {
          return 'terlambat';
        }
      } catch (_) {}
    }

    return 'aktif';
  }

  List<dynamic> get _filteredLoans {
    if (_filter == 'semua') return _loans;
    return _loans.where((l) => _loanStatus(l) == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aktif':
        return AppColors.brandPrimary;
      case 'dikembalikan':
        return AppColors.statusSuccess;
      case 'terlambat':
        return AppColors.statusDanger;
      default:
        return AppColors.textHint;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aktif':
        return 'Aktif';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'terlambat':
        return 'Terlambat';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aktif':
        return Icons.timelapse;
      case 'dikembalikan':
        return Icons.check_circle_outline;
      case 'terlambat':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _markReturned(dynamic loan) async {
    final id = loan['id'];
    if (id == null) return;

    try {
      await _api.dio.put('/gudang/equipment-loans/$id/status', data: {
        'status': 'returned',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status diubah menjadi Dikembalikan')),
        );
        _loadLoans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLoans;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Pinjaman Peralatan',
        accentColor: _roleColor,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _roleColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const EquipmentLoanFormScreen()),
          );
          if (result == true) _loadLoans();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _filterChip('Semua', 'semua'),
                const SizedBox(width: 8),
                _filterChip('Aktif', 'aktif'),
                const SizedBox(width: 8),
                _filterChip('Dikembalikan', 'dikembalikan'),
                const SizedBox(width: 8),
                _filterChip('Terlambat', 'terlambat'),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handyman,
                                size: 48,
                                color: AppColors.textHint.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('Belum ada data pinjaman',
                                style: TextStyle(color: AppColors.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLoans,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildLoanCard(filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      backgroundColor: _roleColor.withValues(alpha: 0.08),
      selectedColor: _roleColor,
      side: BorderSide(
        color: isSelected
            ? _roleColor
            : _roleColor.withValues(alpha: 0.2),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    final map = loan as Map<String, dynamic>;
    final status = _loanStatus(map);
    final color = _statusColor(status);
    final nama = map['nama_almarhum'] ?? '-';
    final rumahDuka = map['rumah_duka'] ?? '-';
    final cp = map['cp_almarhum'] ?? '-';
    final tgl = map['tgl_peringatan']?.toString().split('T')[0] ?? '-';
    final isActive = status == 'aktif' || status == 'terlambat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: color.withValues(alpha: 0.04),
        borderColor: color.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(status), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rumahDuka,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Detail rows
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(cp,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(tgl,
                    style: TextStyle(
                      color: status == 'terlambat'
                          ? AppColors.statusDanger
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: status == 'terlambat'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    )),
              ],
            ),

            // Return button for active/overdue loans
            if (isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReturn(map),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusSuccess,
                    side: BorderSide(
                        color: AppColors.statusSuccess.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.assignment_return, size: 18),
                  label: const Text('Tandai Dikembalikan',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmReturn(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Text(
            'Tandai pinjaman "${loan['nama_almarhum']}" sebagai dikembalikan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markReturned(loan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Dikembalikan'),
          ),
        ],
      ),
    );
  }
}
