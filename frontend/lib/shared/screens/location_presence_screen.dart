import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_widget.dart';

/// v1.40 — Shared check-in/out di lokasi non-kantor
/// (rumah duka, TPU, gereja, rumah keluarga).
///
/// Dipakai oleh semua role internal (SO, Dekor, Driver, Petugas Akta, dll).
/// Melengkapi presensi harian di kantor (daily_attendances).
class LocationPresenceScreen extends StatefulWidget {
  /// Jika dibuka dari order detail, orderId di-pass untuk default input.
  final String? orderId;
  final String? orderNumber;

  const LocationPresenceScreen({super.key, this.orderId, this.orderNumber});

  @override
  State<LocationPresenceScreen> createState() => _LocationPresenceScreenState();
}

class _LocationPresenceScreenState extends State<LocationPresenceScreen> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _currentStatus;
  List<dynamic> _todayLogs = [];

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
      final queryParams = widget.orderId != null ? {'order_id': widget.orderId} : null;

      final results = await Future.wait([
        _api.dio.get('/presence/status'),
        _api.dio.get('/presence', queryParameters: queryParams),
      ]);
      if (!mounted) return;
      setState(() {
        _currentStatus = (results[0].data['data'] as Map?)?.cast<String, dynamic>();
        _todayLogs = (results[1].data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data presensi.';
        _loading = false;
      });
    }
  }

  bool get _isCheckedIn => _currentStatus?['is_checked_in'] == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Presensi Lokasi',
        accentColor: AppColors.brandPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      if (widget.orderNumber != null) ...[
                        _buildOrderInfo(),
                        const SizedBox(height: 16),
                      ],
                      _buildActionButton(),
                      const SizedBox(height: 24),
                      _buildHistoryHeader(),
                      const SizedBox(height: 8),
                      if (_todayLogs.isEmpty)
                        _buildEmpty()
                      else
                        ..._todayLogs.map((l) => _buildLogCard(l)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (!_isCheckedIn) {
      return GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: AppColors.textHint.withValues(alpha: 0.08),
        borderColor: AppColors.textHint.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.location_off, color: AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Sedang Check-In',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Anda belum check-in di lokasi manapun hari ini.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final loc = _currentStatus!['current_location'] as Map<String, dynamic>;
    final checkedInAt = DateTime.parse(loc['checked_in_at']);
    final duration = DateTime.now().difference(checkedInAt);

    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.statusSuccess.withValues(alpha: 0.08),
      borderColor: AppColors.statusSuccess.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.location_on, color: AppColors.statusSuccess, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sedang Check-In',
                      style: TextStyle(
                        color: AppColors.statusSuccess,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc['location_name'] as String? ?? '-',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Sejak ${DateFormat('HH:mm').format(checkedInAt)} (${_formatDuration(duration)})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              _locationTypeBadge(loc['location_type'] as String? ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, size: 16, color: AppColors.brandPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terkait order ${widget.orderNumber}',
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isCheckedIn) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openCheckOutDialog,
          icon: const Icon(Icons.logout),
          label: const Text('Check-Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDanger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openCheckInDialog,
        icon: const Icon(Icons.login),
        label: const Text('Check-In'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusSuccess,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Text(
          'Riwayat Hari Ini',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          '${_todayLogs.length} log',
          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.history, size: 40, color: AppColors.textHint),
            SizedBox(height: 8),
            Text('Belum ada aktivitas hari ini.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(dynamic l) {
    final action = l['action'] as String? ?? '-';
    final isIn = action == 'check_in';
    final color = isIn ? AppColors.statusSuccess : AppColors.statusDanger;
    final ts = DateTime.parse(l['timestamp']);
    final order = l['order'] as Map?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(isIn ? Icons.login : Icons.logout, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l['location_name'] as String? ?? '-',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${isIn ? "Check-In" : "Check-Out"} · ${DateFormat('HH:mm').format(ts)}'
                  '${order != null ? " · ${order['order_number']}" : ""}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          _locationTypeBadge(l['location_type'] as String? ?? ''),
        ],
      ),
    );
  }

  Widget _locationTypeBadge(String type) {
    final label = switch (type) {
      'rumah_duka' => 'Rumah Duka',
      'tpu' => 'TPU',
      'gereja' => 'Gereja',
      'rumah_keluarga' => 'Rumah',
      _ => 'Lainnya',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}j ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
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

  Future<void> _openCheckInDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckInOutSheet(
        action: 'check_in',
        orderId: widget.orderId,
      ),
    );
    if (result == true) _loadAll();
  }

  Future<void> _openCheckOutDialog() async {
    final loc = _currentStatus!['current_location'] as Map<String, dynamic>;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckInOutSheet(
        action: 'check_out',
        orderId: loc['order_id'] as String?,
        prefillLocationType: loc['location_type'] as String?,
        prefillLocationName: loc['location_name'] as String?,
      ),
    );
    if (result == true) _loadAll();
  }
}

/// Bottom sheet: form untuk check-in atau check-out.
class _CheckInOutSheet extends StatefulWidget {
  final String action; // 'check_in' or 'check_out'
  final String? orderId;
  final String? prefillLocationType;
  final String? prefillLocationName;

  const _CheckInOutSheet({
    required this.action,
    this.orderId,
    this.prefillLocationType,
    this.prefillLocationName,
  });

  @override
  State<_CheckInOutSheet> createState() => _CheckInOutSheetState();
}

class _CheckInOutSheetState extends State<_CheckInOutSheet> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  String _locationType = 'rumah_duka';
  final _locationNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  bool get _isCheckIn => widget.action == 'check_in';

  @override
  void initState() {
    super.initState();
    if (widget.prefillLocationType != null) {
      _locationType = widget.prefillLocationType!;
    }
    if (widget.prefillLocationName != null) {
      _locationNameCtrl.text = widget.prefillLocationName!;
    }
  }

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _api.dio.post(
        '/presence/${_isCheckIn ? "check-in" : "check-out"}',
        data: {
          'order_id': widget.orderId,
          'location_type': _locationType,
          'location_name': _locationNameCtrl.text.trim(),
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      String msg = 'Gagal: $e';
      if (e.toString().contains('PRESENCE_ALREADY_OPEN')) {
        msg = 'Sudah check-in di lokasi ini. Check-out dulu.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.statusDanger),
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
                Text(
                  _isCheckIn ? 'Check-In Lokasi' : 'Check-Out Lokasi',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _locationType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Lokasi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rumah_duka', child: Text('Rumah Duka')),
                    DropdownMenuItem(value: 'tpu', child: Text('TPU / Pemakaman')),
                    DropdownMenuItem(value: 'gereja', child: Text('Gereja / Mushola')),
                    DropdownMenuItem(value: 'rumah_keluarga', child: Text('Rumah Keluarga')),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: _isCheckIn ? (v) => setState(() => _locationType = v ?? 'rumah_duka') : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lokasi',
                    border: OutlineInputBorder(),
                    hintText: 'Misal: Rumah Duka Bethesda',
                  ),
                  enabled: _isCheckIn,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

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
                    backgroundColor: _isCheckIn ? AppColors.statusSuccess : AppColors.statusDanger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isCheckIn ? 'Check-In' : 'Check-Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
