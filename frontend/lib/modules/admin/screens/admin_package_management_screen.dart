import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminPackageManagementScreen extends StatefulWidget {
  const AdminPackageManagementScreen({super.key});

  @override
  State<AdminPackageManagementScreen> createState() =>
      _AdminPackageManagementScreenState();
}

class _AdminPackageManagementScreenState
    extends State<AdminPackageManagementScreen> {
  final _api = ApiClient();
  List<dynamic> _packages = [];
  bool _isLoading = true;

  static const _roleColor = AppColors.roleAdmin;
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/admin/packages');
      if (res.data['success'] == true && mounted) {
        setState(() => _packages = List<dynamic>.from(res.data['data'] ?? []));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data paket.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String id, bool currentActive) async {
    try {
      await _api.dio.put('/admin/packages/$id', data: {'is_active': !currentActive});
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal mengubah status.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Manajemen Paket',
        accentColor: _roleColor,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const _PackageFormScreen()),
        ).then((_) => _load()),
        backgroundColor: _roleColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Paket Baru', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _packages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Belum ada paket.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 15)),
                          SizedBox(height: 6),
                          Text('Tekan tombol + untuk menambah paket baru.',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _packages.length,
                      itemBuilder: (_, i) =>
                          _buildPackageCard(_packages[i] as Map<String, dynamic>),
                    ),
            ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final isActive = pkg['is_active'] as bool? ?? true;
    final items = List<dynamic>.from(pkg['items'] ?? []);
    final gudangItems =
        items.where((it) => it['category'] == RoleConstants.gudang).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: isActive ? AppColors.glassWhite : AppColors.backgroundSoft,
        borderColor: isActive
            ? _roleColor.withValues(alpha: 0.2)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg['name'] ?? '-',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (pkg['religion_specific'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          pkg['religion_specific'],
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: _roleColor,
                  activeTrackColor: _roleColor.withValues(alpha: 0.4),
                  onChanged: (_) => _toggleActive(pkg['id'], isActive),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currency.format(
                  double.tryParse(pkg['base_price'].toString()) ?? 0),
              style: const TextStyle(
                  color: _roleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20),
            ),
            if (pkg['description'] != null) ...[
              const SizedBox(height: 4),
              Text(pkg['description'],
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${items.length} item  •  ${gudangItems.length} item gudang',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            ...gudangItems
                .where((it) {
                  final stock = it['stock_item'] as Map<String, dynamic>?;
                  if (stock == null) return false;
                  final curr = (stock['current_quantity'] as num?)?.toInt() ?? 0;
                  final min = (stock['minimum_quantity'] as num?)?.toInt() ?? 0;
                  return curr <= min;
                })
                .map((it) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: AppColors.statusDanger, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Stok ${it['item_name']} kritis!',
                            style: const TextStyle(
                                color: AppColors.statusDanger, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PackageItemsScreen(package: pkg),
                      ),
                    ).then((_) => _load()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _roleColor,
                      side: BorderSide(
                          color: _roleColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.list_alt, size: 15),
                    label: const Text('Kelola Item',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PackageFormScreen(package: pkg),
                      ),
                    ).then((_) => _load()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label:
                        const Text('Edit', style: TextStyle(fontSize: 12)),
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

// ─── Form Buat / Edit Paket ────────────────────────────────────────────────

class _PackageFormScreen extends StatefulWidget {
  final Map<String, dynamic>? package;
  const _PackageFormScreen({this.package});

  @override
  State<_PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<_PackageFormScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  String? _religionSpecific;
  bool _isActive = true;
  bool _isSaving = false;

  static const _roleColor = AppColors.roleAdmin;
  bool get _isEdit => widget.package != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.package?['name'] ?? '');
    _descCtrl = TextEditingController(text: widget.package?['description'] ?? '');
    _priceCtrl = TextEditingController(
        text: widget.package?['base_price']?.toString() ?? '');
    _isActive = widget.package?['is_active'] ?? true;
    _religionSpecific = widget.package?['religion_specific'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'base_price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'religion_specific': _religionSpecific,
        'is_active': _isActive,
      };

      if (_isEdit) {
        await _api.dio.put('/admin/packages/${widget.package!['id']}', data: data);
      } else {
        await _api.dio.post('/admin/packages', data: data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Paket diperbarui.' : 'Paket baru dibuat.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _isEdit ? 'Edit Paket' : 'Paket Baru',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                controller: _nameCtrl,
                label: 'Nama Paket *',
                icon: Icons.inventory_2_outlined,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _priceCtrl,
                label: 'Harga Dasar (Rp) *',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Masukkan angka valid' : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _descCtrl,
                label: 'Deskripsi (opsional)',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _religionSpecific,
                decoration: const InputDecoration(
                  labelText: 'Khusus Agama (opsional)',
                  prefixIcon: Icon(Icons.auto_stories_outlined,
                      color: AppColors.textHint, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Agama')),
                  DropdownMenuItem(value: 'islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'kristen', child: Text('Kristen')),
                  DropdownMenuItem(value: 'katolik', child: Text('Katolik')),
                  DropdownMenuItem(value: 'hindu', child: Text('Hindu')),
                  DropdownMenuItem(value: 'buddha', child: Text('Buddha')),
                  DropdownMenuItem(value: 'konghucu', child: Text('Konghucu')),
                ],
                onChanged: (v) => setState(() => _religionSpecific = v),
              ),
              const SizedBox(height: 14),
              GlassWidget(
                borderRadius: 14,
                blurSigma: 10,
                tint: AppColors.glassWhite,
                borderColor: AppColors.glassBorder,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.toggle_on_outlined,
                        color: AppColors.textHint, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Paket Aktif',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: _roleColor,
                      activeTrackColor: _roleColor.withValues(alpha: 0.4),
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Paket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        ),
        validator: validator,
      );
}

// ─── Kelola Item Paket ─────────────────────────────────────────────────────

class _PackageItemsScreen extends StatefulWidget {
  final Map<String, dynamic> package;
  const _PackageItemsScreen({required this.package});

  @override
  State<_PackageItemsScreen> createState() => _PackageItemsScreenState();
}

class _PackageItemsScreenState extends State<_PackageItemsScreen> {
  final _api = ApiClient();
  List<dynamic> _items = [];
  List<dynamic> _stockItems = [];
  List<String> _providerRoles = ['gudang', 'laviore', 'konsumsi', 'purchasing'];
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
        _api.dio.get('/admin/packages/${widget.package['id']}'),
        _api.dio.get('/admin/stock-items'),
        _api.dio.get('/admin/provider-roles'),
      ]);
      if (!mounted) return;
      if (results[0].data['success'] == true) {
        setState(() => _items = List<dynamic>.from(
            (results[0].data['data']['items'] as List?) ?? []));
      }
      if (results[1].data['success'] == true) {
        setState(() =>
            _stockItems = List<dynamic>.from(results[1].data['data'] ?? []));
      }
      if (results[2].data['success'] == true) {
        setState(() => _providerRoles =
            List<String>.from(results[2].data['data'] ?? _providerRoles));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal memuat data.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: const Text('Item ini akan dihapus dari paket.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.dio
          .delete('/admin/packages/${widget.package['id']}/items/$itemId');
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Gagal menghapus item.')));
      }
    }
  }

  /// Returns stock items filtered by owner_role == providerRole.
  List<dynamic> _stockForRole(String providerRole) =>
      _stockItems.where((s) => s['owner_role'] == providerRole).toList();

  void _showAddItemSheet({Map<String, dynamic>? existingItem}) {
    final isEdit = existingItem != null;

    // Infer initial provider_role from existing item
    String inferRole(Map<String, dynamic> item) {
      if ((item['provider_role'] as String?)?.isNotEmpty == true) {
        return item['provider_role'] as String;
      }
      final cat = item['category'] as String? ?? '';
      return switch (cat) {
        'dekor' => 'laviore',
        'konsumsi' => 'konsumsi',
        'dokumen' => 'purchasing',
        _ => 'gudang',
      };
    }

    String providerRole =
        isEdit ? inferRole(existingItem) : _providerRoles.first;
    String? selectedStockId = isEdit ? existingItem['stock_item_id'] as String? : null;
    final itemNameCtrl = TextEditingController(
        text: isEdit ? existingItem['item_name'] as String? ?? '' : '');
    final unitCtrl = TextEditingController(
        text: isEdit ? existingItem['unit'] as String? ?? '' : '');
    final qtyCtrl = TextEditingController(
        text: isEdit ? existingItem['quantity']?.toString() ?? '1' : '1');
    final notesCtrl = TextEditingController(
        text: isEdit ? existingItem['fulfillment_notes'] as String? ?? '' : '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final roleStockItems = _stockForRole(providerRole);

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
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
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Edit Item Paket' : 'Tambah Item ke Paket',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Provider Role dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _providerRoles.contains(providerRole)
                        ? providerRole
                        : _providerRoles.first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Provider Role *',
                      prefixIcon: Icon(Icons.group_outlined,
                          color: AppColors.textHint, size: 20),
                      helperText: 'Tim yang bertanggung jawab menyiapkan item ini',
                    ),
                    items: _providerRoles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setModal(() {
                      providerRole = v!;
                      selectedStockId = null; // reset stock picker on role change
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Stock picker filtered by role
                  DropdownButtonFormField<String>(
                    initialValue: roleStockItems.any((s) => s['id'] == selectedStockId)
                        ? selectedStockId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Item Stok (opsional)',
                      prefixIcon: const Icon(Icons.inventory_outlined,
                          color: AppColors.textHint, size: 20),
                      helperText: roleStockItems.isEmpty
                          ? 'Belum ada stok untuk role ini — isi nama manual'
                          : 'Jika dipilih, nama & satuan otomatis terisi',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('— Tidak terhubung ke stok —')),
                      ...roleStockItems.map<DropdownMenuItem<String>>((s) {
                        final curr = s['current_quantity'] ?? 0;
                        final min = s['minimum_quantity'] ?? 0;
                        final isLow = curr <= min;
                        return DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Row(
                            children: [
                              if (isLow)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.warning_rounded,
                                      color: AppColors.statusDanger, size: 14),
                                ),
                              Expanded(
                                child: Text(
                                  '${s['item_name']}  (${s['unit']})',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isLow
                                          ? AppColors.statusDanger
                                          : AppColors.textPrimary),
                                ),
                              ),
                              Text('$curr',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isLow
                                          ? AppColors.statusDanger
                                          : AppColors.textHint)),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setModal(() => selectedStockId = v);
                      if (v != null) {
                        final stock = roleStockItems.firstWhere(
                            (s) => s['id'] == v,
                            orElse: () => {});
                        if (stock.isNotEmpty) {
                          itemNameCtrl.text = stock['item_name'] ?? '';
                          unitCtrl.text = stock['unit'] ?? '';
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Item name (manual if no stock selected)
                  TextField(
                    controller: itemNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nama Item *',
                      prefixIcon: Icon(Icons.label_outline,
                          color: AppColors.textHint, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah *',
                            prefixIcon: Icon(Icons.numbers,
                                color: AppColors.textHint, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Satuan *',
                            prefixIcon: Icon(Icons.straighten_outlined,
                                color: AppColors.textHint, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Catatan Pemenuhan (opsional)',
                      prefixIcon: Icon(Icons.notes_outlined,
                          color: AppColors.textHint, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (itemNameCtrl.text.trim().isEmpty ||
                                unitCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Nama item dan satuan wajib diisi.')),
                              );
                              return;
                            }
                            setModal(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final payload = {
                                'stock_item_id': selectedStockId,
                                'item_name': itemNameCtrl.text.trim(),
                                'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                                'unit': unitCtrl.text.trim(),
                                'provider_role': providerRole,
                                if (notesCtrl.text.trim().isNotEmpty)
                                  'fulfillment_notes': notesCtrl.text.trim(),
                              };

                              if (isEdit) {
                                await _api.dio.put(
                                  '/admin/packages/${widget.package['id']}/items/${existingItem['id']}',
                                  data: payload,
                                );
                              } else {
                                await _api.dio.post(
                                  '/admin/packages/${widget.package['id']}/items',
                                  data: payload,
                                );
                              }

                              if (!mounted) return;
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                _load();
                                messenger.showSnackBar(
                                  SnackBar(
                                      content: Text(isEdit
                                          ? 'Item diperbarui.'
                                          : 'Item berhasil ditambahkan.')),
                                );
                              }
                            } catch (e) {
                              setModal(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Gagal: $e')),
                              );
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
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Item'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Item — ${widget.package['name']}',
        accentColor: _roleColor,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        backgroundColor: _roleColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Item', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt,
                              size: 64, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Belum ada item dalam paket ini.',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 6),
                          Text('Tekan + untuk menambah item.',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _items.length,
                      itemBuilder: (_, i) =>
                          _buildItemCard(_items[i] as Map<String, dynamic>),
                    ),
            ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final stock = item['stock_item'] as Map<String, dynamic>?;
    final curr = (stock?['current_quantity'] as num?)?.toInt();
    final min = (stock?['minimum_quantity'] as num?)?.toInt() ?? 0;
    final isLow = curr != null && curr <= min;
    final category = item['category'] as String? ?? '';

    final categoryColors = {
      'gudang': AppColors.roleGudang,
      'dekor': AppColors.roleDekor,
      'konsumsi': AppColors.roleKonsumsi,
      'transportasi': AppColors.roleDriver,
      'dokumen': AppColors.textSecondary,
    };
    final catColor = categoryColors[category] ?? AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: isLow
            ? AppColors.statusDanger.withValues(alpha: 0.04)
            : AppColors.glassWhite,
        borderColor: isLow
            ? AppColors.statusDanger.withValues(alpha: 0.3)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration:
                  BoxDecoration(color: catColor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${item['quantity']} ${item['unit']}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                              color: catColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (stock != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isLow
                              ? Icons.warning_rounded
                              : Icons.check_circle_outline,
                          size: 12,
                          color: isLow
                              ? AppColors.statusDanger
                              : AppColors.statusSuccess,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: ${curr ?? '-'} ${stock['unit'] ?? ''}',
                          style: TextStyle(
                              color: isLow
                                  ? AppColors.statusDanger
                                  : AppColors.textHint,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      '⚠ Belum terhubung ke item stok gudang',
                      style: TextStyle(
                          color: AppColors.statusWarning, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.statusDanger, size: 20),
              onPressed: () => _removeItem(item['id'] as String),
              tooltip: 'Hapus item',
            ),
          ],
        ),
      ),
    );
  }
}
