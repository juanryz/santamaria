import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class HrdShiftManagementScreen extends StatefulWidget {
  const HrdShiftManagementScreen({super.key});

  @override
  State<HrdShiftManagementScreen> createState() => _HrdShiftManagementScreenState();
}

class _HrdShiftManagementScreenState extends State<HrdShiftManagementScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  late TabController _tabCtrl;
  List<dynamic> _shifts = [];
  List<dynamic> _locations = [];
  static const _roleColor = AppColors.roleHrd;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/admin/master/work-shifts'),
        _api.dio.get('/admin/master/attendance-locations'),
      ]);
      if (results[0].data['success'] == true) {
        _shifts = List<dynamic>.from(results[0].data['data'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _locations = List<dynamic>.from(results[1].data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Shift & Lokasi',
        accentColor: _roleColor,
        bottom: TabBar(controller: _tabCtrl, labelColor: _roleColor, tabs: const [
          Tab(text: 'Shift Kerja'),
          Tab(text: 'Lokasi Presensi'),
        ]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildShiftsTab(),
              _buildLocationsTab(),
            ]),
    );
  }

  Widget _buildShiftsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts.length,
      itemBuilder: (_, i) {
        final s = _shifts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _roleColor.withValues(alpha: 0.12)),
                child: const Icon(Icons.schedule, color: AppColors.roleHrd),
              ),
              title: Text(s['shift_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s['start_time'] ?? ''} — ${s['end_time'] ?? ''}\nToleransi telat: ${s['late_tolerance_minutes'] ?? 0} mnt',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (_, i) {
        final l = _locations[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassWidget(
            borderRadius: 14,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.12)),
                child: const Icon(Icons.location_on, color: Colors.blue),
              ),
              title: Text(l['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${l['address'] ?? ''}\nRadius: ${l['radius_meters'] ?? 100}m',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
}
