import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminApproveOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const AdminApproveOrderScreen({super.key, required this.order});

  @override
  State<AdminApproveOrderScreen> createState() =>
      _AdminApproveOrderScreenState();
}

class _AdminApproveOrderScreenState extends State<AdminApproveOrderScreen> {
  final _api = ApiClient();

  bool _isLoading = false;
  bool _loadingResources = true;
  DateTime? _scheduledAt;
  Map<String, dynamic>? _selectedDriver;
  Map<String, dynamic>? _selectedVehicle;
  final _notesCtrl = TextEditingController();

  List<dynamic> _drivers = [];
  List<dynamic> _vehicles = [];

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    // Resources (drivers/vehicles) are loaded AFTER schedule is picked
    // because the API requires scheduled_at for conflict checking
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadResources(String scheduledAt) async {
    if (mounted) setState(() => _loadingResources = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/admin/drivers/available', queryParameters: {'scheduled_at': scheduledAt}),
        _api.dio.get('/admin/vehicles/available', queryParameters: {'scheduled_at': scheduledAt}),
      ]);
      if (results[0].data['success'] == true) {
        _drivers = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _vehicles = List<dynamic>.from(results[1].data['data'] ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingResources = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    setState(() {
      _scheduledAt = picked;
      // Reset selections when schedule changes
      _selectedDriver = null;
      _selectedVehicle = null;
    });
    // Load available resources for this schedule
    _loadResources(picked.toIso8601String());
  }

  Future<void> _submit() async {
    if (_scheduledAt == null) {
      _snack('Pilih jadwal terlebih dahulu.');
      return;
    }
    if (_selectedDriver == null) {
      _snack('Pilih driver terlebih dahulu.');
      return;
    }
    if (_selectedVehicle == null) {
      _snack('Pilih kendaraan terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.put(
        '/admin/orders/${widget.order['id']}/approve',
        data: {
          'scheduled_at': _scheduledAt!.toIso8601String(),
          'driver_id': _selectedDriver!['id'],
          'vehicle_id': _selectedVehicle!['id'],
          'admin_notes': _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Order berhasil disetujui! Notifikasi dikirim ke semua pihak.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _snack(res.data['message'] ?? 'Gagal menyetujui order.');
      }
    } catch (e) {
      _snack('Terjadi kesalahan. Periksa konflik jadwal driver/kendaraan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Setujui Order',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  GlassWidget(
                    borderRadius: 16,
                    blurSigma: 16,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order['deceased_name'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['pickup_address'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '→ ${order['destination_address'] ?? '-'}',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel('1. Jadwal Keberangkatan'),
                  const SizedBox(height: 10),
                  _schedulePicker(),
                  const SizedBox(height: 24),

                  _sectionLabel('2. Pilih Driver'),
                  const SizedBox(height: 10),
                  if (_scheduledAt == null)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Pilih jadwal dulu untuk melihat driver tersedia.',
                          style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    )
                  else if (_loadingResources)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildDriverList(),
                  const SizedBox(height: 24),

                  _sectionLabel('3. Pilih Kendaraan'),
                  const SizedBox(height: 10),
                  if (_scheduledAt == null)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Pilih jadwal dulu untuk melihat kendaraan tersedia.',
                          style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    )
                  else if (_loadingResources)
                    const SizedBox.shrink()
                  else
                    _buildVehicleList(),
                  const SizedBox(height: 24),

                  _sectionLabel('4. Catatan Admin (opsional)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText:
                          'Instruksi khusus untuk driver atau vendor...',
                      labelText: 'Catatan',
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: Text(
                        _isLoading ? 'Memproses...' : 'KONFIRMASI PERSETUJUAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusSuccess,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
              color: _roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.4),
        ),
      );

  Widget _schedulePicker() {
    return GestureDetector(
      onTap: _pickDateTime,
      child: GlassWidget(
        borderRadius: 14,
        blurSigma: 16,
        tint: _scheduledAt != null
            ? _roleColor.withValues(alpha: 0.06)
            : AppColors.glassWhite,
        borderColor: _scheduledAt != null
            ? _roleColor.withValues(alpha: 0.20)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                color: _scheduledAt != null ? _roleColor : AppColors.textHint,
                size: 22),
            const SizedBox(width: 14),
            Text(
              _scheduledAt != null
                  ? DateFormat('EEEE, d MMMM yyyy — HH:mm', 'id')
                      .format(_scheduledAt!)
                  : 'Ketuk untuk pilih jadwal',
              style: TextStyle(
                color: _scheduledAt != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverList() {
    if (_drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Text('Tidak ada driver tersedia.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: _drivers.map((d) {
        final isSelected = _selectedDriver?['id'] == d['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedDriver = d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? _roleColor
                    : AppColors.textHint.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? _roleColor.withValues(alpha: 0.08)
                  : AppColors.backgroundSoft,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSelected
                      ? _roleColor.withValues(alpha: 0.15)
                      : AppColors.textHint.withValues(alpha: 0.12),
                  child: Text(
                    (d['name'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        color: isSelected ? _roleColor : AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(d['phone'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: _roleColor, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Text('Tidak ada kendaraan tersedia.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: _vehicles.map((v) {
        final isSelected = _selectedVehicle?['id'] == v['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedVehicle = v),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? _roleColor
                    : AppColors.textHint.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? _roleColor.withValues(alpha: 0.08)
                  : AppColors.backgroundSoft,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.directions_car,
                    color: isSelected ? _roleColor : AppColors.textHint),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['model'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(v['plate_number'] ?? '-',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: _roleColor, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
