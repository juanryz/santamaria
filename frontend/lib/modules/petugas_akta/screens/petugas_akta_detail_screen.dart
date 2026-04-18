import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'package:dio/dio.dart';
import 'death_cert_progress_screen.dart';

class PetugasAktaDetailScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String deceasedName;

  const PetugasAktaDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.deceasedName,
  });

  @override
  State<PetugasAktaDetailScreen> createState() =>
      _PetugasAktaDetailScreenState();
}

class _PetugasAktaDetailScreenState extends State<PetugasAktaDetailScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _detail = {};

  static const _roleColor = Color(0xFF8E44AD);

  static const _statusFlow = [
    'collecting_docs',
    'submitted_to_civil',
    'processing',
    'completed',
    'handed_to_family',
  ];

  static const _statusLabels = {
    'collecting_docs': 'Mengumpulkan Berkas',
    'submitted_to_civil': 'Diajukan ke Capil',
    'processing': 'Diproses Capil',
    'completed': 'Akta Selesai',
    'handed_to_family': 'Diserahkan ke Keluarga',
  };

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
      final res =
          await _api.dio.get('/petugas-akta/orders/${widget.orderId}');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _detail = Map<String, dynamic>.from(res.data['data'] ?? {}));
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

  String get _currentStatus =>
      (_detail['death_cert_status'] as String?) ?? 'collecting_docs';

  int get _currentIndex => _statusFlow.indexOf(_currentStatus);

  List<dynamic> get _docItems =>
      List<dynamic>.from(_detail['death_cert_items'] ?? []);

  List<dynamic> get _progressLog {
    final raw = _detail['catatan'];
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) return parsed;
      } catch (_) {}
    }
    return [];
  }

  String? get _nextStatus {
    final idx = _currentIndex;
    if (idx < 0 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  Color _statusColor(String? status) => switch (status) {
        'collecting_docs' => Colors.orange,
        'submitted_to_civil' => Colors.blue,
        'processing' => Colors.indigo,
        'completed' => Colors.teal,
        'handed_to_family' => Colors.green.shade700,
        _ => Colors.grey,
      };

  String _formatDate(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID')
          .format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  Future<void> _showUpdateSheet() async {
    final next = _nextStatus;
    if (next == null) return;

    final notesCtl = TextEditingController();
    final locationCtl = TextEditingController();
    String selectedStatus = next;
    XFile? photo;
    bool submitting = false;

    final availableStatuses = <String>[];
    for (int i = _currentIndex + 1; i < _statusFlow.length; i++) {
      // Skip handed_to_family — that has its own button
      if (_statusFlow[i] == 'handed_to_family') continue;
      availableStatuses.add(_statusFlow[i]);
    }
    if (availableStatuses.isEmpty) return;
    selectedStatus = availableStatuses.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Update Progress',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Baru',
                    border: OutlineInputBorder(),
                  ),
                  items: availableStatuses
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_statusLabels[s] ?? s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Keterangan progress...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtl,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Kunjungan',
                    hintText: 'Misal: Kantor Disdukcapil Semarang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
                    if (picked != null) {
                      setSheetState(() => photo = picked);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(photo != null ? 'Foto diambil' : 'Ambil Foto'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            setSheetState(() => submitting = true);
                            try {
                              final formData = FormData.fromMap({
                                'status': selectedStatus,
                                if (notesCtl.text.trim().isNotEmpty)
                                  'notes': notesCtl.text.trim(),
                                if (locationCtl.text.trim().isNotEmpty)
                                  'visit_location': locationCtl.text.trim(),
                                if (photo != null)
                                  'photo': await MultipartFile.fromFile(
                                      photo!.path,
                                      filename: photo!.name),
                              });
                              await _api.dio.put(
                                '/petugas-akta/orders/${widget.orderId}/progress',
                                data: formData,
                                options: Options(
                                    contentType: 'multipart/form-data'),
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Progress berhasil diperbarui.')),
                              );
                              _load();
                            } catch (e) {
                              setSheetState(() => submitting = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Gagal memperbarui. Coba lagi.')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handOver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serahkan ke Keluarga?'),
        content: const Text(
            'Pastikan akta kematian sudah dicetak dan siap diserahkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
            child: const Text('Serahkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.dio
          .post('/petugas-akta/orders/${widget.orderId}/hand-over');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akta berhasil diserahkan ke keluarga.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Gagal menyerahkan akta. Coba lagi.';
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.orderNumber,
        accentColor: _roleColor,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline, color: _roleColor),
            tooltip: 'Progress v1.40',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeathCertProgressScreen(orderId: widget.orderId),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
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

  Widget _buildBody() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTimeline(),
          const SizedBox(height: 20),
          _buildDocChecklist(),
          const SizedBox(height: 20),
          _buildProgressLog(),
          const SizedBox(height: 20),
          _buildActions(),
          const SizedBox(height: 40),
        ],
      );

  Widget _buildHeader() => GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: _roleColor.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deceasedName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(widget.orderNumber,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildTimeline() => GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Progress',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...List.generate(_statusFlow.length, (i) {
              final s = _statusFlow[i];
              final isDone = i <= _currentIndex;
              final isCurrent = i == _currentIndex;
              final color = isDone ? _statusColor(s) : AppColors.textHint;
              final isLast = i == _statusFlow.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? color
                              : Colors.transparent,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: isDone
                              ? color.withValues(alpha: 0.5)
                              : AppColors.textHint.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _statusLabels[s] ?? s,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w400,
                          color: isDone
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );

  Widget _buildDocChecklist() {
    final items = _docItems;
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Checklist Dokumen',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (items.isNotEmpty)
                Text(
                  '${items.where((d) => d['diterima_sm'] == true).length}/${items.length}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Belum ada dokumen.',
                style: TextStyle(
                    color: AppColors.textHint, fontSize: 13))
          else
            ...items.map((doc) {
              final checked = doc['diterima_sm'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      checked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: checked ? Colors.green.shade700 : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc['doc_name']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: checked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProgressLog() {
    final logs = _progressLog;
    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Progress',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Text('Belum ada catatan progress.',
                style:
                    TextStyle(color: AppColors.textHint, fontSize: 13))
          else
            ...logs.reversed.map((log) {
              final entry = log is Map ? log : {};
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry['status'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(entry['status']?.toString())
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabels[entry['status']] ??
                              entry['status'].toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                _statusColor(entry['status']?.toString()),
                          ),
                        ),
                      ),
                    if (entry['notes'] != null)
                      Text(entry['notes'].toString(),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                    if (entry['visit_location'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                                entry['visit_location'].toString(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                    if (entry['date'] != null) ...[
                      const SizedBox(height: 2),
                      Text(_formatDate(entry['date']?.toString()),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActions() => Column(
        children: [
          if (_nextStatus != null && _currentStatus != 'handed_to_family')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showUpdateSheet,
                icon: const Icon(Icons.edit_note),
                label: const Text('Update Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_currentStatus == 'completed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handOver,
                icon: const Icon(Icons.handshake),
                label: const Text('Serahkan ke Keluarga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      );
}
