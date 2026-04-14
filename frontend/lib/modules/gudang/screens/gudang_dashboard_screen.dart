import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'gudang_orders_screen.dart';
import 'coffin_order_list_screen.dart';
import 'stock_alert_screen.dart';
import 'equipment_loan_list_screen.dart';
import 'stock_form_screen.dart';
import 'vehicle_maintenance_screen.dart';

class GudangDashboardScreen extends StatefulWidget {
  const GudangDashboardScreen({super.key});

  @override
  State<GudangDashboardScreen> createState() => _GudangDashboardScreenState();
}

class _GudangDashboardScreenState extends State<GudangDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  int _tab = 0; // 0=Order Aktif, 1=Manajemen Stok, 2=Pengadaan (e-Katalog)
  int _pendingOrderCount = 0;
  
  List<dynamic> _stocks = [];
  List<dynamic> _procurements = [];

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Load active orders to get badge count
      try {
        final ordersRes = await _api.dio.get('/gudang/orders');
        if (ordersRes.data['success'] == true) {
          final all = List<dynamic>.from(ordersRes.data['data'] ?? []);
          _pendingOrderCount = all.where((o) => o['status'] == 'pending' || o['status'] == 'confirmed' || o['status'] == 'approved').length;
        }
      } catch (_) {}

      // 2. Load Stock List
      try {
        final stockRes = await _api.dio.get('/gudang/stock');
        if (stockRes.data['success'] == true) {
          _stocks = List<dynamic>.from(stockRes.data['data'] ?? []);
        }
      } catch (_) {}

      // 3. Load Procurements (e-Katalog)
      try {
        final procRes = await _api.dio.get('/gudang/procurement-requests');
        if (procRes.data['data'] != null) {
          _procurements = List<dynamic>.from(procRes.data['data'] ?? []);
        } else if (procRes.data is List) {
          _procurements = List<dynamic>.from(procRes.data);
        }
      } catch (_) {}

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?['name'] ?? 'Gudang';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 180, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Portal Gudang & Stok',
                                style: TextStyle(
                                    color: _roleColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Halo, $userName',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const Spacer(),
                        GlassWidget(
                          borderRadius: 12,
                          blurSigma: 10,
                          tint: AppColors.glassWhite,
                          borderColor: AppColors.glassBorder,
                          padding: const EdgeInsets.all(8),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            await context.read<AuthProvider>().logout();
                            if (!mounted) return;
                            nav.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                              (_) => false,
                            );
                          },
                          child: const Icon(Icons.logout, color: AppColors.textSecondary, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab selector
                    GlassWidget(
                      borderRadius: 50,
                      blurSigma: 10,
                      tint: AppColors.glassWhite,
                      borderColor: AppColors.glassBorder,
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _pillBtn('Order Aktif', 0, badge: _pendingOrderCount),
                          _pillBtn('Inventori', 1),
                          _pillBtn('Pengadaan', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_tab == 0) ...[
                      _buildActiveOrdersTab(),
                    ] else if (_tab == 1) ...[
                      _buildStockTab(),
                    ] else ...[
                      _buildProcurementTab(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickMenuChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: _roleColor),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: _roleColor.withValues(alpha: 0.08),
      side: BorderSide(color: _roleColor.withValues(alpha: 0.2)),
      onPressed: onTap,
    );
  }

  Widget _pillBtn(String label, int index, {int badge = 0}) {
    final isSelected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _roleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 4),
                Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: AppColors.statusDanger, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    return Column(
      children: [
        GlassWidget(
          borderRadius: 16,
          blurSigma: 16,
          tint: _roleColor.withValues(alpha: 0.06),
          borderColor: _roleColor.withValues(alpha: 0.15),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.roleGudang, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proses Cek Stok Order', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Text(
                    '$_pendingOrderCount order menunggu penyiapan barang.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const GudangOrdersScreen()));
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _roleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.checklist_rounded, size: 20),
            label: const Text('Buka Daftar Order Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- TAB INVENTORI / STOK ---

  Widget _buildStockTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // v1.14 Quick Access Menu
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _quickMenuChip(Icons.inventory_2, 'Workshop Peti', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoffinOrderListScreen()));
            }),
            _quickMenuChip(Icons.warning_amber, 'Alert Stok', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StockAlertScreen()));
            }),
            _quickMenuChip(Icons.handyman, 'Pinjaman Peralatan', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentLoanListScreen()));
            }),
            _quickMenuChip(Icons.swap_vert, 'Ambil/Kembali Barang', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StockFormScreen()));
            }),
            _quickMenuChip(Icons.build, 'Maintenance Kendaraan', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleMaintenanceScreen()));
            }),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manajemen Stok Item', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.roleGudang),
              onPressed: () => _showAddStockDialog(),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (_stocks.isEmpty)
          const Text('Belum ada data stok.', style: TextStyle(color: AppColors.textHint))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stocks.length,
            itemBuilder: (ctx, i) {
              final stock = _stocks[i];
              final qty = stock['current_quantity'] ?? 0;
              final minQty = stock['minimum_quantity'] ?? 0;
              final isCritical = qty <= minQty;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassWidget(
                  borderRadius: 16,
                  blurSigma: 10,
                  tint: isCritical ? AppColors.statusDanger.withValues(alpha: 0.05) : AppColors.glassWhite,
                  borderColor: isCritical ? AppColors.statusDanger.withValues(alpha: 0.3) : AppColors.glassBorder,
                  padding: const EdgeInsets.all(16),
                  onTap: () => _showEditStockDialog(stock),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCritical ? AppColors.statusDanger.withValues(alpha: 0.1) : _roleColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inventory, color: isCritical ? AppColors.statusDanger : _roleColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock['item_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
                            Text('Kategori: ${stock['category'] ?? '-'}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$qty ${stock['unit']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isCritical ? AppColors.statusDanger : AppColors.textPrimary)),
                          if (isCritical)
                            const Text('Limit Habis!', style: TextStyle(color: AppColors.statusDanger, fontSize: 10, fontWeight: FontWeight.bold))
                          else
                            Text('Min: $minQty', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddStockDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Tambah Data Stok'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Barang')),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Kategori (contoh: Peti)')),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Stok Awal'), keyboardType: TextInputType.number),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Satuan (contoh: pcs)')),
            TextField(controller: minQtyCtrl, decoration: const InputDecoration(labelText: 'Minimum Stok (Warning)'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              final payload = {
                'item_name': nameCtrl.text,
                'category': catCtrl.text,
                'current_quantity': int.tryParse(qtyCtrl.text) ?? 0,
                'unit': unitCtrl.text,
                'minimum_quantity': int.tryParse(minQtyCtrl.text) ?? 0,
              };
              await _api.dio.post('/gudang/stock', data: payload);
              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambah stok')));
            }
          },
          child: const Text('Simpan'),
        )
      ],
    ));
  }

  void _showEditStockDialog(Map<String, dynamic> stock) {
    final qtyCtrl = TextEditingController(text: stock['current_quantity']?.toString());
    
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Edit Stok: ${stock['item_name']}'),
      content: TextField(
        controller: qtyCtrl, 
        decoration: const InputDecoration(labelText: 'Jumlah Tersedia Saat Ini'), 
        keyboardType: TextInputType.number
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              await _api.dio.put('/gudang/stock/${stock['id']}', data: {
                'current_quantity': int.tryParse(qtyCtrl.text) ?? 0,
              });
              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal update')));
            }
          },
          child: const Text('Update'),
        )
      ],
    ));
  }

  // --- TAB PENGADAAN (PROCUREMENT) ---

  Widget _buildProcurementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Request Pengadaan (e-Katalog)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: AppColors.roleGudang),
              onPressed: () => _showAddProcurementDialog(),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (_procurements.isEmpty)
          const Text('Belum ada request pengadaan.', style: TextStyle(color: AppColors.textHint))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _procurements.length,
            itemBuilder: (ctx, i) {
              final pr = _procurements[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassWidget(
                  borderRadius: 16,
                  blurSigma: 10,
                  tint: AppColors.glassWhite,
                  borderColor: AppColors.glassBorder,
                  padding: const EdgeInsets.all(16),
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: _roleColor, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pr['item_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
                            Text('${pr['request_number']} • Qty: ${pr['quantity']}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: _roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                         child: Text(pr['status'] ?? '-', style: const TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddProcurementDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final addressCtrl = TextEditingController(text: 'Gudang Pusat Santa Maria');
    
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Buat Request Pengadaan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Barang')),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Jumlah Kebutuhan'), keyboardType: TextInputType.number),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Satuan')),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Pengiriman')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            try {
              final payload = {
                'item_name': nameCtrl.text,
                'category': catCtrl.text,
                'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                'unit': unitCtrl.text,
                'delivery_address': addressCtrl.text,
                'status': 'draft',
              };
              final res = await _api.dio.post('/gudang/procurement-requests', data: payload);
              if (mounted) {
                // Auto-publish it immediately for e-Katalog
                if (res.data != null && res.data['id'] != null) {
                   await _api.dio.put('/gudang/procurement-requests/${res.data['id']}/publish');
                }
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengadaan diajukan ke Supplier!')));
                _loadData();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal buat pengadaan')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white),
          child: const Text('Submit & Publikasi'),
        )
      ],
    ));
  }
}
