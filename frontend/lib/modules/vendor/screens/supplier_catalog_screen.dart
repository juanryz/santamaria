import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'supplier_quote_form_screen.dart';

class SupplierCatalogScreen extends StatefulWidget {
  const SupplierCatalogScreen({super.key});

  @override
  State<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends State<SupplierCatalogScreen> {
  final SupplierRepository _repository = SupplierRepository(ApiClient());
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _allOrders = [];
  List<dynamic> _filtered = [];

  static const _roleColor = AppColors.roleSupplier;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _repository.getAvailablePurchaseOrders();
      if (!mounted) return;
      if (resp.data['success'] == true) {
        _allOrders = List<dynamic>.from(resp.data['data'] ?? []);
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
      _filtered = query.isEmpty
          ? List<dynamic>.from(_allOrders)
          : _allOrders
              .where((o) => (o['item_name'] as String? ?? '')
                  .toLowerCase()
                  .contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Katalog Permintaan',
        accentColor: _roleColor,
        showBack: true,
        actions: [
          GlassWidget(
            borderRadius: 12,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(8),
            onTap: _loadOrders,
            child: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari nama barang…',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textHint, size: 20),
                labelText: 'Cari',
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${_filtered.length} permintaan tersedia',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada permintaan tersedia.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final order = _filtered[index];
                            return _OrderCard(
                              order: order,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SupplierQuoteFormScreen(
                                        purchaseOrder:
                                            Map<String, dynamic>.from(order)),
                                  ),
                                );
                                _loadOrders();
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
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            Text(
              order['item_name'] ?? 'Barang',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${order['quantity']} ${order['unit']}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Est. ${order['proposed_price']}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.roleSupplier.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.roleSupplier.withValues(alpha: 0.40)),
                  ),
                  child: const Text(
                    'Ajukan Penawaran →',
                    style: TextStyle(
                        color: AppColors.roleSupplier,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
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
