import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminFleetManagementScreen extends StatefulWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  State<AdminFleetManagementScreen> createState() =>
      _AdminFleetManagementScreenState();
}

class _AdminFleetManagementScreenState
    extends State<AdminFleetManagementScreen> {
  final _api = ApiClient();
  List<dynamic> _vehicles = [];
  List<dynamic> _packages = [];
  bool _isLoading = true;

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/admin/vehicles'),
        _api.dio.get('/admin/packages'),
      ]);
      if (!mounted) return;

      if (results[0].data['success'] == true) {
        setState(() => _vehicles = List<dynamic>.from(results[0].data['data'] ?? []));
      }
      if (results[1].data['success'] == true) {
        setState(() => _packages = List<dynamic>.from(results[1].data['data'] ?? []));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data armada.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    try {
      await _api.dio.put('/admin/vehicles/$id', data: {'is_active': !current});
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal mengubah status.')));
      }
    }
  }

  void _showVehicleForm([Map<String, dynamic>? vehicle]) {
    final plateCtrl =
        TextEditingController(text: vehicle?['plate_number'] ?? '');
    final modelCtrl = TextEditingController(text: vehicle?['model'] ?? '');
    final capCtrl =
        TextEditingController(text: vehicle?['capacity']?.toString() ?? '1');
    String type = vehicle?['type'] ?? 'jenazah';
    String? packageId = vehicle?['package_id'];
    bool isActive = vehicle?['is_active'] ?? true;
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();
    final isEdit = vehicle != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: plateCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nomor Plat *',
                    prefixIcon: Icon(Icons.pin, color: AppColors.textHint, size: 20),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Model / Merek *',
                    prefixIcon: Icon(Icons.directions_car_outlined,
                        color: AppColors.textHint, size: 20),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Kapasitas (orang) *',
                    prefixIcon:
                        Icon(Icons.people_outline, color: AppColors.textHint, size: 20),
                  ),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Masukkan angka' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Kendaraan *',
                    prefixIcon: Icon(Icons.local_shipping_outlined,
                        color: AppColors.textHint, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'jenazah', child: Text('Mobil Jenazah')),
                    DropdownMenuItem(
                        value: 'ambulans', child: Text('Ambulans')),
                    DropdownMenuItem(
                        value: 'operasional', child: Text('Operasional')),
                  ],
                  onChanged: (v) => setModal(() => type = v!),
                ),
                const SizedBox(height: 12),
                if (type == 'jenazah' && _packages.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: packageId,
                    decoration: const InputDecoration(
                      labelText: 'Peruntukan Paket',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppColors.textHint, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Umum / Tanpa Paket Spesifik')),
                      ..._packages.map((p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(p['name'] as String))),
                    ],
                    onChanged: (v) => setModal(() => packageId = v),
                  ),
                  const SizedBox(height: 12),
                ],
                GlassWidget(
                  borderRadius: 12,
                  blurSigma: 8,
                  tint: AppColors.glassWhite,
                  borderColor: AppColors.glassBorder,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('Aktif',
                              style:
                                  TextStyle(color: AppColors.textPrimary))),
                      Switch(
                        value: isActive,
                        activeThumbColor: _roleColor,
                        activeTrackColor: _roleColor.withValues(alpha: 0.4),
                        onChanged: (v) => setModal(() => isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModal(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final data = {
                              'plate_number': plateCtrl.text.trim().toUpperCase(),
                              'model': modelCtrl.text.trim(),
                              'capacity': int.tryParse(capCtrl.text) ?? 1,
                              'type': type,
                              'package_id': type == 'jenazah' ? packageId : null,
                              'is_active': isActive,
                            };
                            if (isEdit) {
                              await _api.dio.put(
                                  '/admin/vehicles/${vehicle['id']}',
                                  data: data);
                            } else {
                              await _api.dio
                                  .post('/admin/vehicles', data: data);
                            }
                            if (!mounted || !ctx.mounted) return;
                            Navigator.pop(ctx);
                            _load();
                            messenger.showSnackBar(SnackBar(
                                content: Text(isEdit
                                    ? 'Kendaraan diperbarui.'
                                    : 'Kendaraan ditambahkan.')));
                          } catch (e) {
                            setModal(() => isSaving = false);
                            messenger.showSnackBar(
                                SnackBar(content: Text('Gagal: $e')));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _vehicles.where((v) => v['is_active'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Manajemen Armada',
        accentColor: _roleColor,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleForm(),
        backgroundColor: _roleColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // Summary pill
                  GlassWidget(
                    borderRadius: 16,
                    blurSigma: 10,
                    tint: _roleColor.withValues(alpha: 0.07),
                    borderColor: _roleColor.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            color: _roleColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '$activeCount dari ${_vehicles.length} kendaraan aktif',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Driver di-assign otomatis oleh AI saat order dikonfirmasi.',
                    style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  if (_vehicles.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Belum ada kendaraan terdaftar.',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ..._vehicles.map((v) => _buildVehicleCard(
                        v as Map<String, dynamic>)),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    final isActive = v['is_active'] as bool? ?? true;
    final type = v['type'] as String? ?? 'jenazah';

    final typeIcons = {
      'jenazah': Icons.local_shipping,
      'ambulans': Icons.emergency,
      'operasional': Icons.directions_car,
    };
    final typeLabels = {
      'jenazah': 'Mobil Jenazah',
      'ambulans': 'Ambulans',
      'operasional': 'Operasional',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 18,
        blurSigma: 12,
        tint: isActive ? AppColors.glassWhite : AppColors.backgroundSoft,
        borderColor: isActive
            ? _roleColor.withValues(alpha: 0.15)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isActive ? _roleColor : AppColors.textHint)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcons[type] ?? Icons.directions_car,
                  color: isActive ? _roleColor : AppColors.textHint,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['plate_number'] ?? '-',
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${v['model'] ?? '-'}  •  ${typeLabels[type] ?? type}  •  ${v['capacity'] ?? 1} orang',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (type == 'jenazah' && v['package'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Untuk: ${v['package']['name']}',
                        style: const TextStyle(
                            color: _roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: isActive,
                  activeThumbColor: _roleColor,
                  activeTrackColor: _roleColor.withValues(alpha: 0.4),
                  onChanged: (_) => _toggleActive(v['id'], isActive),
                ),
                InkWell(
                  onTap: () => _showVehicleForm(v),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        color: AppColors.textHint, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
