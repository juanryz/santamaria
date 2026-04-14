import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Driver vehicle management — KM logs, fuel, inspection, maintenance.
class DriverVehicleScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleModel;
  const DriverVehicleScreen({super.key, required this.vehicleId, required this.vehicleModel});

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  static const _roleColor = AppColors.roleDriver;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _logKm(String type) async {
    final kmCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log KM ($type)'),
        content: TextField(controller: kmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pembacaan KM')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (result == true && kmCtrl.text.isNotEmpty) {
      try {
        await _api.dio.post('/driver/vehicles/${widget.vehicleId}/km-log', data: {
          'log_type': type,
          'km_reading': double.parse(kmCtrl.text),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KM recorded')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _logFuel() async {
    final litersCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '13900');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Isi BBM'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: litersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liter')),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga/Liter (Rp)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (result == true && litersCtrl.text.isNotEmpty) {
      try {
        await _api.dio.post('/driver/vehicles/${widget.vehicleId}/fuel-logs', data: {
          'liters': double.parse(litersCtrl.text),
          'price_per_liter': double.parse(priceCtrl.text),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fuel log recorded')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reportMaintenance() async {
    final descCtrl = TextEditingController();
    String category = 'other';
    String priority = 'medium';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lapor Kerusakan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: const [
                DropdownMenuItem(value: 'engine', child: Text('Mesin')),
                DropdownMenuItem(value: 'brake', child: Text('Rem')),
                DropdownMenuItem(value: 'tire', child: Text('Ban')),
                DropdownMenuItem(value: 'body', child: Text('Body')),
                DropdownMenuItem(value: 'electrical', child: Text('Kelistrikan')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (v) => category = v!,
            ),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi masalah *')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
        ],
      ),
    );

    if (result == true && descCtrl.text.isNotEmpty) {
      try {
        await _api.dio.post('/driver/vehicles/${widget.vehicleId}/maintenance-requests', data: {
          'category': category,
          'priority': priority,
          'description': descCtrl.text,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan kerusakan dikirim')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.vehicleModel,
        accentColor: _roleColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _roleColor,
          isScrollable: true,
          tabs: const [Tab(text: 'Quick Action'), Tab(text: 'KM Log'), Tab(text: 'BBM'), Tab(text: 'Maintenance')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Quick Actions
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _actionCard('Log KM Mulai', Icons.play_circle, Colors.green, () => _logKm('start')),
              _actionCard('Log KM Selesai', Icons.stop_circle, Colors.red, () => _logKm('end')),
              _actionCard('Isi BBM', Icons.local_gas_station, Colors.blue, _logFuel),
              _actionCard('Lapor Kerusakan', Icons.warning_amber, Colors.orange, _reportMaintenance),
            ],
          ),
          // KM Log tab (placeholder — will load from API)
          const Center(child: Text('Riwayat KM')),
          // Fuel tab
          const Center(child: Text('Riwayat BBM')),
          // Maintenance tab
          const Center(child: Text('Riwayat Maintenance')),
        ],
      ),
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
            child: Icon(icon, color: color),
          ),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
