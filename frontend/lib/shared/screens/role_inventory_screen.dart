import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_widget.dart';

class RoleInventoryScreen extends StatefulWidget {
  const RoleInventoryScreen({super.key});

  @override
  State<RoleInventoryScreen> createState() => _RoleInventoryScreenState();
}

class _RoleInventoryScreenState extends State<RoleInventoryScreen> {
  final _api = ApiClient();
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/role-stock/items');
      if (res.data['success'] == true && mounted) {
        setState(() => _items = List<dynamic>.from(res.data['data'] ?? []));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat inventaris.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final minQtyCtrl = TextEditingController(text: '0');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.backgroundSoft,
          title: const Text('Tambah Item Inventaris',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Nama Item *', Icons.inventory_2_outlined),
                const SizedBox(height: 12),
                _dialogField(categoryCtrl, 'Kategori *', Icons.category_outlined),
                const SizedBox(height: 12),
                _dialogField(unitCtrl, 'Satuan *', Icons.straighten_outlined),
                const SizedBox(height: 12),
                _dialogField(qtyCtrl, 'Jumlah Saat Ini *', Icons.numbers,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(minQtyCtrl, 'Stok Minimum', Icons.warning_amber_outlined,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roleAdmin),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          categoryCtrl.text.trim().isEmpty ||
                          unitCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Nama, kategori, dan satuan wajib diisi.')),
                        );
                        return;
                      }
                      setDialog(() => isSaving = true);
                      try {
                        await _api.dio.post('/role-stock/items', data: {
                          'item_name': nameCtrl.text.trim(),
                          'category': categoryCtrl.text.trim(),
                          'unit': unitCtrl.text.trim(),
                          'current_quantity':
                              int.tryParse(qtyCtrl.text.trim()) ?? 0,
                          'minimum_quantity':
                              int.tryParse(minQtyCtrl.text.trim()) ?? 0,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setDialog(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateQtyDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController(
        text: item['current_quantity']?.toString() ?? '0');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.backgroundSoft,
          title: Text(
            item['item_name'] ?? '-',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
          ),
          content: _dialogField(
              qtyCtrl, 'Jumlah Saat Ini', Icons.numbers,
              keyboardType: TextInputType.number),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roleAdmin),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialog(() => isSaving = true);
                      try {
                        await _api.dio
                            .put('/role-stock/items/${item['id']}', data: {
                          'current_quantity':
                              int.tryParse(qtyCtrl.text.trim()) ?? 0,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setDialog(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSoft,
        title: const Text('Hapus Item?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Item ini akan dihapus dari inventaris Anda.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.dio.delete('/role-stock/items/$id');
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus item.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Inventaris Saya',
        accentColor: AppColors.roleGudang,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.roleGudang,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Item', style: TextStyle(color: Colors.white)),
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
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text('Belum ada item inventaris.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15)),
                          SizedBox(height: 6),
                          Text('Tekan + untuk menambah item.',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _items.length,
                      itemBuilder: (_, i) =>
                          _buildItemCard(_items[i] as Map<String, dynamic>),
                    ),
            ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final curr = (item['current_quantity'] as num?)?.toInt() ?? 0;
    final min = (item['minimum_quantity'] as num?)?.toInt() ?? 0;
    final isLow = curr <= min;

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
            Expanded(
              child: InkWell(
                onTap: () => _showUpdateQtyDialog(item),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLow)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.warning_rounded,
                                color: AppColors.statusDanger, size: 16),
                          ),
                        Expanded(
                          child: Text(
                            item['item_name'] ?? '-',
                            style: TextStyle(
                              color: isLow
                                  ? AppColors.statusDanger
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['category'] ?? '-'}  •  ${item['unit'] ?? ''}',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: min > 0
                            ? (curr / (min * 2)).clamp(0.0, 1.0)
                            : 1.0,
                        backgroundColor: AppColors.glassBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLow
                              ? AppColors.statusDanger
                              : AppColors.statusSuccess,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: $curr  •  Min: $min  ${item['unit'] ?? ''}',
                      style: TextStyle(
                        color: isLow
                            ? AppColors.statusDanger
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.statusDanger, size: 20),
              onPressed: () => _deleteItem(item['id'] as String),
              tooltip: 'Hapus item',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        ),
      );
}
