import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_catalog_detail_screen.dart';

class SupplierCatalogScreen extends StatefulWidget {
  const SupplierCatalogScreen({super.key});

  @override
  State<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends State<SupplierCatalogScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _allRequests = [];
  List<dynamic> _filtered = [];
  List<String> _categories = [];
  String? _selectedCategory;

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/supplier/procurement-requests');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _allRequests = List<dynamic>.from(res.data['data'] ?? []);
        final cats = <String>{};
        for (final r in _allRequests) {
          final c = r['category'] as String?;
          if (c != null && c.isNotEmpty) cats.add(c);
        }
        _categories = cats.toList()..sort();
        _applyFilter();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat katalog.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allRequests.where((r) {
        final name = (r['item_name'] as String? ?? '').toLowerCase();
        final cat = r['category'] as String? ?? '';
        final matchSearch = query.isEmpty || name.contains(query);
        final matchCat =
            _selectedCategory == null || cat == _selectedCategory;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  String _formatCurrency(dynamic value) {
    final num = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Katalog Pengadaan',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: _loadData,
            child: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textHint, size: 20),
                labelText: 'Cari',
              ),
            ),
          ),

          // Category chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chipBtn('Semua', null),
                  ..._categories.map((c) => _chipBtn(c, c)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} permintaan tersedia',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('Belum ada permintaan tersedia.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final r = _filtered[i];
                            return _RequestCard(
                              request: r,
                              formatCurrency: _formatCurrency,
                              formatDate: _formatDate,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SupplierCatalogDetailScreen(
                                            requestId:
                                                r['id'].toString()),
                                  ),
                                );
                                _loadData();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chipBtn(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12)),
        selected: isSelected,
        selectedColor: _roleColor,
        backgroundColor: AppColors.backgroundSoft,
        side: BorderSide.none,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          _applyFilter();
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String Function(dynamic) formatCurrency;
  final String Function(String?) formatDate;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.formatCurrency,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final quoteCount = request['quotes_count'] ?? request['quote_count'] ?? 0;
    final deadline = request['quote_deadline'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 16,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['item_name'] ?? 'Barang',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (request['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.roleSupplier.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(request['category'],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.inventory_2_outlined,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text('${request['quantity']} ${request['unit'] ?? ''}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              if (request['max_price'] != null) ...[
                const Icon(Icons.price_check,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                Text('Maks ${formatCurrency(request['max_price'])}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text('Deadline: ${formatDate(deadline)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.people_outline,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text('$quoteCount penawaran',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.roleSupplier.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.roleSupplier.withValues(alpha: 0.40)),
                ),
                child: const Text('Lihat Detail ->',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
