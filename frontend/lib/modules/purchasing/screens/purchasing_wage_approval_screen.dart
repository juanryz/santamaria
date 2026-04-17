import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class PurchasingWageApprovalScreen extends StatefulWidget {
  const PurchasingWageApprovalScreen({super.key});

  @override
  State<PurchasingWageApprovalScreen> createState() =>
      _PurchasingWageApprovalScreenState();
}

class _PurchasingWageApprovalScreenState
    extends State<PurchasingWageApprovalScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _claims = [];
  String _filterRole = 'all';
  String _filterStatus = 'pending';

  static const _roleColor = AppColors.rolePurchasing;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _roles = const [
    {'value': 'all', 'label': 'Semua Role'},
    {'value': 'tukang_jaga', 'label': 'Tukang Jaga'},
    {'value': 'tukang_angkat_peti', 'label': 'Tukang Angkat Peti'},
    {'value': 'tukang_foto', 'label': 'Tukang Foto'},
    {'value': 'musisi', 'label': 'Musisi'},
  ];

  final _statuses = const [
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'approved', 'label': 'Disetujui'},
    {'value': 'rejected', 'label': 'Ditolak'},
    {'value': 'all', 'label': 'Semua'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterRole != 'all') params['role'] = _filterRole;
      if (_filterStatus != 'all') params['status'] = _filterStatus;

      final res = await _api.dio.get(
        '/finance/wage-claims',
        queryParameters: params,
      );
      if (res.data['success'] == true) {
        _claims = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  Future<void> _approve(String id) async {
    try {
      await _api.dio.put('/finance/wage-claims/$id/approve');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upah disetujui'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyetujui upah')),
        );
      }
    }
  }

  Future<void> _reject(String id) async {
    final reason = await _showReasonDialog();
    if (reason == null || reason.isEmpty) return;
    try {
      await _api.dio.put(
        '/finance/wage-claims/$id/reject',
        data: {'reason': reason},
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upah ditolak')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menolak upah')),
        );
      }
    }
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSoft,
        title: const Text(
          'Alasan Penolakan',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Masukkan alasan...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.statusSuccess;
      case 'rejected':
        return AppColors.statusDanger;
      case 'pending':
        return AppColors.statusWarning;
      default:
        return AppColors.textHint;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu';
      default:
        return status;
    }
  }

  String _roleName(String? role) {
    switch (role) {
      case 'tukang_jaga':
        return 'Tukang Jaga';
      case 'tukang_angkat_peti':
        return 'Tukang Angkat Peti';
      case 'tukang_foto':
        return 'Tukang Foto';
      case 'musisi':
        return 'Musisi';
      default:
        return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Approval Upah Pekerja',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: _filterRole,
                      items: _roles,
                      onChanged: (v) {
                        setState(() => _filterRole = v!);
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      value: _filterStatus,
                      items: _statuses,
                      onChanged: (v) {
                        setState(() => _filterStatus = v!);
                        _loadData();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _claims.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada klaim upah',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _claims.length,
                          itemBuilder: (_, i) => _buildClaimCard(_claims[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e['value'],
                    child: Text(e['label']!),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    final name = claim['claimant_name'] as String? ?? '-';
    final role = claim['claimant_role'] as String? ?? '-';
    final orderNumber = claim['order_number'] as String? ?? '-';
    final amount = _toDouble(claim['amount']);
    final status = claim['status'] as String? ?? 'pending';
    final id = claim['id']?.toString() ?? '';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: isPending
            ? AppColors.statusWarning.withValues(alpha: 0.04)
            : AppColors.glassWhite,
        borderColor: isPending
            ? AppColors.statusWarning.withValues(alpha: 0.2)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _roleColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _roleColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _roleName(role),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GlassStatusBadge(
                  label: _statusLabel(status),
                  color: _statusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.receipt_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Order: $orderNumber',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _currency.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(id),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.statusDanger,
                        size: 16,
                      ),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(color: AppColors.statusDanger),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              AppColors.statusDanger.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approve(id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
