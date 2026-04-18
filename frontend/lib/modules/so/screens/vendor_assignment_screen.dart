import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.24/v1.40 — SO kelola vendor assignment per order.
///
/// Internal (dari SM pool) vs External (bawa sendiri consumer/SO).
/// Enforcement v1.40:
/// - Vendor dengan is_paid_by_sm=false → fee di-force 0 oleh backend
/// - Pemuka agama → selalu external + fee=0 + user_id null
class VendorAssignmentScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const VendorAssignmentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<VendorAssignmentScreen> createState() => _VendorAssignmentScreenState();
}

class _VendorAssignmentScreenState extends State<VendorAssignmentScreen> {
  final _api = ApiClient();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _loading = true;
  String? _error;
  List<dynamic> _assignments = [];
  List<dynamic> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.dio.get('/so/orders/${widget.orderId}/vendor-assignments'),
        _api.dio.get('/so/vendor-roles'),
      ]);
      if (!mounted) return;
      setState(() {
        _assignments = (results[0].data['data'] as List?) ?? [];
        _availableRoles = (results[1].data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat vendor.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Tim Vendor — ${widget.orderNumber}',
        accentColor: AppColors.roleSO,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _assignments.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _assignments.length,
                        itemBuilder: (_, i) => _buildAssignmentCard(_assignments[i]),
                      ),
      ),
      floatingActionButton: _availableRoles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAssignDialog,
              backgroundColor: AppColors.roleSO,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Assign Vendor', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final role = a['vendor_role'] ?? {};
    final roleName = role['role_name'] as String? ?? '-';
    final roleIcon = role['icon'] as String?;
    final isPaidBySm = role['is_paid_by_sm'] != false;

    final source = a['source'] as String? ?? '-';
    final isInternal = source == 'internal';
    final userName = isInternal ? (a['user']?['name'] as String? ?? '-') : (a['ext_name'] as String? ?? '-');
    final userPhone = isInternal ? (a['user']?['phone'] as String?) : (a['ext_phone'] as String?);

    final status = a['status'] as String? ?? 'assigned';
    final statusColor = _statusColor(status);

    final fee = double.tryParse('${a['fee']}') ?? 0;
    final waContacted = a['wa_contacted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: statusColor.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.roleSO.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconFromName(roleIcon),
                    size: 18,
                    color: AppColors.roleSO,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Source badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInternal
                        ? AppColors.statusInfo.withValues(alpha: 0.1)
                        : AppColors.statusWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sourceLabel(source),
                    style: TextStyle(
                      color: isInternal ? AppColors.statusInfo : AppColors.statusWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPaidBySm)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Keluarga Bayar',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (isPaidBySm && fee > 0)
                  Text(
                    _currency.format(fee),
                    style: const TextStyle(
                      color: AppColors.roleSO,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (!isInternal && userPhone != null && userPhone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactViaWa(a, userPhone),
                      icon: Icon(
                        Icons.chat_outlined,
                        size: 14,
                        color: waContacted ? AppColors.statusSuccess : Colors.green,
                      ),
                      label: Text(
                        waContacted ? 'Sudah Dihubungi ✓' : 'Hubungi via WA',
                        style: TextStyle(
                          fontSize: 11,
                          color: waContacted ? AppColors.statusSuccess : Colors.green,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: (waContacted ? AppColors.statusSuccess : Colors.green)
                              .withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!['present', 'completed'].contains(status)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusDanger),
                    onPressed: () => _confirmDelete(a),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'assigned' => AppColors.statusInfo,
        'confirmed' => AppColors.statusSuccess,
        'present' => AppColors.statusSuccess,
        'declined' => AppColors.statusDanger,
        'no_show' => AppColors.statusDanger,
        'completed' => AppColors.textSecondary,
        _ => AppColors.textHint,
      };

  String _statusLabel(String status) => switch (status) {
        'assigned' => 'Ditugaskan',
        'confirmed' => 'Konfirmasi',
        'present' => 'Hadir',
        'declined' => 'Ditolak',
        'no_show' => 'Tidak Hadir',
        'completed' => 'Selesai',
        _ => status,
      };

  String _sourceLabel(String source) => switch (source) {
        'internal' => 'Internal SM',
        'external_consumer' => 'Dari Keluarga',
        'external_so' => 'Dari SO',
        _ => source,
      };

  IconData _iconFromName(String? name) => switch (name) {
        'music_note' => Icons.music_note,
        'religion' => Icons.church,
        'photo_camera' => Icons.photo_camera,
        'flower' => Icons.local_florist,
        'restaurant' => Icons.restaurant,
        _ => Icons.person_outline,
      };

  Future<void> _contactViaWa(dynamic assignment, String phone) async {
    final role = assignment['vendor_role']?['role_name'] as String? ?? 'Vendor';
    final name = assignment['ext_name'] as String? ?? '';

    await WhatsAppService.openChat(
      phone: phone,
      message: 'Selamat pagi $name,\n'
          'Saya dari Santa Maria Funeral Organizer. '
          'Mohon kesediaan Bapak/Ibu untuk bertugas sebagai $role '
          'pada order ${widget.orderNumber}. Terima kasih.',
    );

    // Mark as contacted
    try {
      await _api.dio
          .put('/so/orders/${widget.orderId}/vendor-assignments/${assignment['id']}/wa-contacted');
      _loadAll();
    } catch (_) {}
  }

  Future<void> _confirmDelete(dynamic a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Assignment?'),
        content: Text(
          'Vendor ${a['vendor_role']?['role_name'] ?? '-'} akan dihapus dari order.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.dio
          .delete('/so/orders/${widget.orderId}/vendor-assignments/${a['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment dihapus'), backgroundColor: AppColors.statusSuccess),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  Future<void> _openAssignDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignVendorSheet(
        orderId: widget.orderId,
        availableRoles: _availableRoles,
      ),
    );
    if (result == true) _loadAll();
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusDanger),
              const SizedBox(height: 12),
              Text(_error ?? '', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('Belum ada vendor di-assign.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              SizedBox(height: 4),
              Text('Tambahkan via tombol + di bawah.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Form sheet untuk assign vendor baru.
class _AssignVendorSheet extends StatefulWidget {
  final String orderId;
  final List<dynamic> availableRoles;

  const _AssignVendorSheet({required this.orderId, required this.availableRoles});

  @override
  State<_AssignVendorSheet> createState() => _AssignVendorSheetState();
}

class _AssignVendorSheetState extends State<_AssignVendorSheet> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  String? _selectedRoleId;
  String _source = 'internal';
  final _extNameCtrl = TextEditingController();
  final _extPhoneCtrl = TextEditingController();
  final _extOrgCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  dynamic get _selectedRole =>
      widget.availableRoles.firstWhere((r) => r['id'] == _selectedRoleId, orElse: () => null);

  bool get _isPaidBySm => (_selectedRole?['is_paid_by_sm'] ?? true) == true;

  bool get _isPemukaAgama => _selectedRole?['role_code'] == 'pemuka_agama';

  @override
  void dispose() {
    _extNameCtrl.dispose();
    _extPhoneCtrl.dispose();
    _extOrgCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Force rules sebelum submit (UI hint — backend tetap enforce)
    final sourceToSend = _isPemukaAgama && _source == 'internal' ? 'external_consumer' : _source;
    final feeToSend = _isPaidBySm ? double.tryParse(_feeCtrl.text) ?? 0 : 0;

    try {
      await _api.dio.post(
        '/so/orders/${widget.orderId}/vendor-assignments',
        data: {
          'vendor_role_id': _selectedRoleId,
          'source': sourceToSend,
          if (sourceToSend == 'internal') ...{
            // user_id akan dipilih via screen lain, placeholder
          },
          if (sourceToSend != 'internal') ...{
            'ext_name': _extNameCtrl.text.trim(),
            'ext_phone': _extPhoneCtrl.text.trim(),
            'ext_organization': _extOrgCtrl.text.trim().isEmpty ? null : _extOrgCtrl.text.trim(),
          },
          'fee': feeToSend,
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Assign Vendor',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Pilih jenis vendor
                DropdownButtonFormField<String>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Vendor',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.availableRoles
                      .map((r) => DropdownMenuItem<String>(
                            value: r['id'] as String,
                            child: Text(r['role_name'] as String? ?? '-'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedRoleId = v;
                      if (_isPemukaAgama && _source == 'internal') {
                        _source = 'external_consumer';
                      }
                    });
                  },
                  validator: (v) => v == null ? 'Pilih jenis vendor' : null,
                ),

                // Warning untuk pemuka agama
                if (_isPemukaAgama) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusInfo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.statusInfo),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pemuka agama dibayar langsung oleh keluarga, bukan via SM.',
                            style: TextStyle(color: AppColors.statusInfo, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Sumber vendor
                DropdownButtonFormField<String>(
                  value: _source,
                  decoration: const InputDecoration(
                    labelText: 'Sumber',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    if (!_isPemukaAgama)
                      const DropdownMenuItem(value: 'internal', child: Text('Internal SM')),
                    const DropdownMenuItem(
                      value: 'external_consumer',
                      child: Text('Dari Keluarga'),
                    ),
                    const DropdownMenuItem(value: 'external_so', child: Text('Dari SO')),
                  ],
                  onChanged: (v) => setState(() => _source = v ?? 'internal'),
                ),
                const SizedBox(height: 12),

                // Kalau external: input nama + phone
                if (_source != 'internal') ...[
                  TextFormField(
                    controller: _extNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Vendor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _extPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'No. WhatsApp',
                      border: OutlineInputBorder(),
                      hintText: '08xxx',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _extOrgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Organisasi (opsional)',
                      border: OutlineInputBorder(),
                      hintText: 'Paroki / Mushola / Katering XYZ',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Fee — hanya kalau is_paid_by_sm=true
                if (_selectedRole != null && _isPaidBySm) ...[
                  TextFormField(
                    controller: _feeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Biaya (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                ] else if (_selectedRole != null && !_isPaidBySm) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Fee = Rp 0 (keluarga bayar langsung, SM tidak tag)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleSO,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Assign'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
