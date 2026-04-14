import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class _MasterEntity {
  final String slug;
  final String displayName;
  final IconData icon;

  const _MasterEntity(this.slug, this.displayName, this.icon);
}

const _entities = [
  _MasterEntity('consumables', 'Bahan Habis Pakai', Icons.science_outlined),
  _MasterEntity('billing-items', 'Item Tagihan', Icons.receipt_long_outlined),
  _MasterEntity('coffin-stages', 'Tahap Produksi Peti', Icons.carpenter_outlined),
  _MasterEntity('coffin-qc-criteria', 'Kriteria QC Peti', Icons.checklist_outlined),
  _MasterEntity('death-cert-docs', 'Dokumen Akta Kematian', Icons.description_outlined),
  _MasterEntity('dekor-items', 'Item Dekorasi', Icons.palette_outlined),
  _MasterEntity('equipment', 'Peralatan', Icons.build_outlined),
  _MasterEntity('vendor-roles', 'Role Vendor', Icons.badge_outlined),
  _MasterEntity('trip-legs', 'Rute Perjalanan', Icons.route_outlined),
  _MasterEntity('wa-templates', 'Template WhatsApp', Icons.chat_outlined),
  _MasterEntity('status-labels', 'Label Status', Icons.label_outlined),
  _MasterEntity('terms', 'Syarat & Ketentuan', Icons.gavel_outlined),
  _MasterEntity('attendance-locations', 'Lokasi Presensi', Icons.location_on_outlined),
  _MasterEntity('work-shifts', 'Shift Kerja', Icons.schedule_outlined),
  _MasterEntity('vehicle-inspection', 'Inspeksi Kendaraan', Icons.directions_car_outlined),
  _MasterEntity('packages', 'Paket Layanan', Icons.inventory_2_outlined),
];

class SuperAdminMasterDataScreen extends StatelessWidget {
  const SuperAdminMasterDataScreen({super.key});

  static const _accent = AppColors.roleSuperAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Master Data',
        accentColor: _accent,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: _entities.length,
            itemBuilder: (context, index) {
              final e = _entities[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey(e.slug),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + index * 40),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassWidget(
                    borderRadius: 16,
                    blurSigma: 14,
                    tint: AppColors.glassWhite,
                    borderColor: AppColors.glassBorder,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _EntityListScreen(entity: e),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(e.icon, color: _accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            e.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntityListScreen extends StatefulWidget {
  final _MasterEntity entity;
  const _EntityListScreen({required this.entity});

  @override
  State<_EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<_EntityListScreen> {
  static const _accent = AppColors.roleSuperAdmin;
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  String get _endpoint => '/admin/master/${widget.entity.slug}';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get(_endpoint);
      final data = res.data is Map && res.data['data'] != null ? res.data['data'] : res.data;
      _items = List<Map<String, dynamic>>.from(data is List ? data : []);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<String> _editableKeys(Map<String, dynamic> item) {
    const skip = {'id', 'created_at', 'updated_at', 'deleted_at'};
    return item.keys.where((k) => !skip.contains(k)).toList();
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final keys = existing != null
        ? _editableKeys(existing)
        : (_items.isNotEmpty ? _editableKeys(_items.first) : ['name']);
    final controllers = <String, TextEditingController>{};
    for (final k in keys) {
      controllers[k] = TextEditingController(
        text: existing != null ? '${existing[k] ?? ''}' : '',
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: GlassWidget(
            borderRadius: 24,
            blurSigma: 20,
            tint: AppColors.glassWhite,
            borderColor: _accent.withValues(alpha: 0.2),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                        color: AppColors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing != null ? 'Edit Item' : 'Tambah Item',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...keys.map((k) {
                    final label = k.replaceAll('_', ' ');
                    final upperLabel = label[0].toUpperCase() + label.substring(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[k],
                        decoration: InputDecoration(
                          labelText: upperLabel,
                        ),
                        maxLines: k.contains('description') || k.contains('body') || k.contains('content') ? 3 : 1,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final body = <String, dynamic>{};
                        for (final k in keys) {
                          final val = controllers[k]!.text.trim();
                          if (val.isEmpty) continue;
                          final asNum = num.tryParse(val);
                          body[k] = asNum ?? val;
                        }
                        Navigator.pop(ctx);
                        try {
                          if (existing != null) {
                            await _api.dio.put('$_endpoint/${existing['id']}', data: body);
                          } else {
                            await _api.dio.post(_endpoint, data: body);
                          }
                          _fetch();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')),
                            );
                          }
                        }
                      },
                      child: Text(existing != null ? 'Simpan' : 'Tambah'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Item'),
        content: Text(
          'Hapus "${item['name'] ?? item['item_name'] ?? 'item ini'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.dio.delete('$_endpoint/${item['id']}');
                _fetch();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal hapus: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.statusDanger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _itemTitle(Map<String, dynamic> item) {
    return '${item['name'] ?? item['item_name'] ?? item['label'] ?? item['title'] ?? 'ID ${item['id']}'}';
  }

  String _itemSubtitle(Map<String, dynamic> item) {
    final keys = _editableKeys(item);
    final titleKey = ['name', 'item_name', 'label', 'title'].firstWhere(
      (k) => item.containsKey(k),
      orElse: () => '',
    );
    final others = keys.where((k) => k != titleKey).take(2);
    return others.map((k) => '${k.replaceAll('_', ' ')}: ${item[k]}').join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.entity.displayName,
        accentColor: _accent,
        actions: [
          GlassIconButton(
            icon: Icons.refresh,
            onPressed: _fetch,
            color: _accent,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? _buildShimmer()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.statusDanger, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, color: AppColors.textHint, size: 56),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada data',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _accent,
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(item['id'] ?? index),
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + index * 35),
                            curve: Curves.easeOut,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: ValueKey(item['id'] ?? index),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusDanger.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
                                ),
                                confirmDismiss: (_) async {
                                  _confirmDelete(item);
                                  return false;
                                },
                                child: GlassWidget(
                                  borderRadius: 16,
                                  blurSigma: 14,
                                  tint: AppColors.glassWhite,
                                  borderColor: AppColors.glassBorder,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  onTap: () => _showForm(existing: item),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: _accent.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(widget.entity.icon, color: _accent, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _itemTitle(item),
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (_itemSubtitle(item).isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                _itemSubtitle(item),
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _confirmDelete(item),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.textHint,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 8,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassWidget(
              borderRadius: 16,
              blurSigma: 14,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
