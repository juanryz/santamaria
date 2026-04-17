import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class SecurityIncidentScreen extends StatefulWidget {
  const SecurityIncidentScreen({super.key});

  @override
  State<SecurityIncidentScreen> createState() => _SecurityIncidentScreenState();
}

class _SecurityIncidentScreenState extends State<SecurityIncidentScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = Color(0xFF636E72);
  bool _isLoading = true;
  List<dynamic> _incidents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/security/incidents');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _incidents = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.statusDanger;
      case 'warning':
        return AppColors.statusWarning;
      default:
        return AppColors.statusInfo;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'visitor':
        return 'Tamu';
      case 'property_damage':
        return 'Kerusakan';
      case 'theft_attempt':
        return 'Pencurian';
      case 'unauthorized_access':
        return 'Akses Ilegal';
      case 'vehicle_incident':
        return 'Kendaraan';
      case 'fire_hazard':
        return 'Kebakaran';
      default:
        return 'Lainnya';
    }
  }

  void _showReportForm() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final visitorNameCtrl = TextEditingController();
    final visitorPhoneCtrl = TextEditingController();
    final visitorPurposeCtrl = TextEditingController();
    String selectedType = 'other';
    String selectedSeverity = 'info';
    File? photoFile;

    const typeOptions = [
      ('visitor', 'Tamu'),
      ('property_damage', 'Kerusakan Properti'),
      ('theft_attempt', 'Percobaan Pencurian'),
      ('unauthorized_access', 'Akses Tidak Sah'),
      ('vehicle_incident', 'Insiden Kendaraan'),
      ('fire_hazard', 'Bahaya Kebakaran'),
      ('other', 'Lainnya'),
    ];
    const severityOptions = [
      ('info', 'Info'),
      ('warning', 'Warning'),
      ('critical', 'Critical'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.fromLTRB(8, 60, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Lapor Insiden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  // Type
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Jenis Insiden'),
                    items: typeOptions.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                    onChanged: (v) => setSheetState(() => selectedType = v ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  // Severity
                  DropdownButtonFormField<String>(
                    initialValue: selectedSeverity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: severityOptions.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
                    onChanged: (v) => setSheetState(() => selectedSeverity = v ?? 'info'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul *')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi *'), maxLines: 3),
                  const SizedBox(height: 12),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Lokasi')),
                  // Visitor fields
                  if (selectedType == 'visitor') ...[
                    const SizedBox(height: 12),
                    TextField(controller: visitorNameCtrl, decoration: const InputDecoration(labelText: 'Nama Tamu')),
                    const SizedBox(height: 12),
                    TextField(controller: visitorPhoneCtrl, decoration: const InputDecoration(labelText: 'Telepon Tamu'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextField(controller: visitorPurposeCtrl, decoration: const InputDecoration(labelText: 'Tujuan Kunjungan')),
                  ],
                  const SizedBox(height: 16),
                  // Photo
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
                          if (picked != null) setSheetState(() => photoFile = File(picked.path));
                        },
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Ambil Foto'),
                      ),
                      if (photoFile != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 4),
                        const Text('Foto diambil', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _roleColor),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan deskripsi wajib diisi')));
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          final formData = FormData.fromMap({
                            'incident_type': selectedType,
                            'severity': selectedSeverity,
                            'title': titleCtrl.text,
                            'description': descCtrl.text,
                            if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text,
                            if (selectedType == 'visitor') ...{
                              if (visitorNameCtrl.text.isNotEmpty) 'visitor_name': visitorNameCtrl.text,
                              if (visitorPhoneCtrl.text.isNotEmpty) 'visitor_phone': visitorPhoneCtrl.text,
                              if (visitorPurposeCtrl.text.isNotEmpty) 'visitor_purpose': visitorPurposeCtrl.text,
                            },
                            if (photoFile != null) 'photos[]': await MultipartFile.fromFile(photoFile!.path),
                          });
                          await _api.dio.post('/security/incidents', data: formData);
                          _loadData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insiden dilaporkan')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      },
                      child: const Text('Kirim Laporan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Insiden', accentColor: _roleColor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _roleColor,
        onPressed: _showReportForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _incidents.isEmpty
                ? ListView(children: const [SizedBox(height: 200), Center(child: Text('Belum ada insiden'))])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incidents.length,
                    itemBuilder: (_, i) {
                      final inc = _incidents[i];
                      final type = inc['incident_type'] ?? 'other';
                      final severity = inc['severity'] ?? 'info';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(inc['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    GlassStatusBadge(label: _typeLabel(type), color: _roleColor),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    GlassStatusBadge(label: severity.toString().toUpperCase(), color: _severityColor(severity)),
                                    const Spacer(),
                                    Text(
                                      inc['created_at'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if (inc['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(inc['description'], style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                if (inc['location'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Lokasi: ${inc['location']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
