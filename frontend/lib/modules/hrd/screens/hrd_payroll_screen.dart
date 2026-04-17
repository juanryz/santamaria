import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_config.dart';

class HrdPayrollScreen extends StatefulWidget {
  const HrdPayrollScreen({super.key});

  @override
  State<HrdPayrollScreen> createState() => _HrdPayrollScreenState();
}

class _HrdPayrollScreenState extends State<HrdPayrollScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = AppColors.roleHrd;

  bool _isLoading = false;
  bool _isGenerating = false;
  List<dynamic> _payrollList = [];

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayroll();
  }

  Future<void> _loadPayroll() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/hrd/payroll',
        queryParameters: {'year': _selectedYear, 'month': _selectedMonth},
      );
      if (res.data['success'] == true) {
        _payrollList = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {
      _payrollList = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _generatePayroll() async {
    setState(() => _isGenerating = true);
    try {
      await _api.dio.post(
        '/hrd/payroll/generate',
        data: {'year': _selectedYear, 'month': _selectedMonth},
      );
      await _loadPayroll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll berhasil di-generate.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal generate payroll.')),
        );
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _approvePayroll(String id) async {
    try {
      await _api.dio.put('/hrd/payroll/$id/approve');
      await _loadPayroll();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payroll approved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal approve payroll.')));
      }
    }
  }

  void _exportPdf() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/hrd/payroll/export?year=$_selectedYear&month=$_selectedMonth',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is num)
        ? amount.toInt()
        : int.tryParse('$amount') ?? 0;
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'paid' => AppColors.statusSuccess,
      'approved' => Colors.blue,
      'reviewed' => Colors.orange,
      _ => AppColors.statusPending,
    };
  }

  void _showDetail(dynamic item) {
    final tasksCompleted = item['tasks_completed'] ?? 0;
    final tasksTotal = item['tasks_total'] ?? 1;
    final completionRate = item['completion_rate'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item['employee_name'] ?? '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              item['role'] ?? '-',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _detailRow('Gaji Pokok', _formatCurrency(item['base_salary'])),
            _detailRow('Tugas Selesai', '$tasksCompleted / $tasksTotal'),
            _detailRow('Tingkat Penyelesaian', '$completionRate%'),
            _detailRow('Gaji Final', _formatCurrency(item['final_salary'])),
            _detailRow('Status', item['status'] ?? 'draft'),
            const SizedBox(height: 16),
            if (item['status'] != 'approved' && item['status'] != 'paid')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                  onPressed: () {
                    Navigator.pop(context);
                    _approvePayroll('${item['id']}');
                  },
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Payroll',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: Column(
        children: [
          // Period selector + actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Bulan',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_months[i]),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            _selectedMonth = v;
                            _loadPayroll();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Tahun',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: List.generate(5, (i) {
                          final y = DateTime.now().year - 2 + i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }),
                        onChanged: (v) {
                          if (v != null) {
                            _selectedYear = v;
                            _loadPayroll();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high),
                        label: const Text('Generate Payroll'),
                        onPressed: _isGenerating ? null : _generatePayroll,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        onPressed: _exportPdf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payrollList.isEmpty
                ? const Center(
                    child: Text('Belum ada data payroll untuk periode ini.'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPayroll,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _payrollList.length,
                      itemBuilder: (_, i) {
                        final item = _payrollList[i];
                        final tasksCompleted = item['tasks_completed'] ?? 0;
                        final tasksTotal = item['tasks_total'] ?? 1;
                        final rate = (tasksTotal > 0)
                            ? tasksCompleted / tasksTotal
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassWidget(
                            borderRadius: 14,
                            onTap: () => _showDetail(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['employee_name'] ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              item['role'] ?? '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GlassStatusBadge(
                                        label: item['status'] ?? 'draft',
                                        color: _statusColor(
                                          item['status'] ?? 'draft',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        'Tugas: $tasksCompleted/$tasksTotal',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: rate.toDouble(),
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation(
                                              _roleColor,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(rate * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Pokok: ${_formatCurrency(item['base_salary'])}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(item['final_salary']),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
