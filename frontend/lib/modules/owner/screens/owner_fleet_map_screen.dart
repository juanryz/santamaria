import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// Owner fleet map — menampilkan lokasi semua karyawan aktif secara real-time.
/// Driver (dari GPS order) dan semua karyawan lain (dari user location tracking).
class OwnerFleetMapScreen extends StatefulWidget {
  const OwnerFleetMapScreen({super.key});

  @override
  State<OwnerFleetMapScreen> createState() => _OwnerFleetMapScreenState();
}

class _OwnerFleetMapScreenState extends State<OwnerFleetMapScreen> {
  final ApiClient _api = ApiClient();
  final MapController _mapCtrl = MapController();
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Semua karyawan dengan lokasi terbaru
  List<Map<String, dynamic>> _employeeLocations = [];

  // Filter berdasarkan role
  String _selectedRole = 'semua';

  static const _roleColor = AppColors.roleOwner;

  // Warna per role (menggunakan AppColors yang tersedia)
  static const _roleColors = <String, Color>{
    'driver':          AppColors.roleDriver,
    'service_officer': AppColors.roleSO,
    'admin':           AppColors.roleAdmin,
    'gudang':          AppColors.roleGudang,
    'finance':         AppColors.roleFinance,
    'hrd':             AppColors.roleHrd,
    'dekor':           AppColors.roleDekor,
    'tukang_foto':     AppColors.roleTukangFoto,
    'tukang_jaga':     AppColors.roleTukangAngkatPeti,
    'vendor':          AppColors.roleSupplier,
  };

  static const _roleIcons = <String, IconData>{
    'driver':          Icons.directions_car,
    'service_officer': Icons.support_agent,
    'admin':           Icons.admin_panel_settings,
    'gudang':          Icons.warehouse,
    'finance':         Icons.account_balance,
    'hrd':             Icons.people,
    'dekor':           Icons.format_paint,
    'tukang_foto':     Icons.camera_alt,
    'tukang_jaga':     Icons.security,
    'vendor':          Icons.store,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final res = await _api.dio.get('/owner/employee-locations');
      if (res.data['success'] == true) {
        final list = List<Map<String, dynamic>>.from(
          (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
        if (mounted) setState(() => _employeeLocations = list);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedRole == 'semua') return _employeeLocations;
    return _employeeLocations.where((e) => e['role'] == _selectedRole).toList();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final emp in _filtered) {
      final loc = emp['location'] as Map<String, dynamic>?;
      if (loc == null) continue;
      final lat = double.tryParse(loc['latitude']?.toString() ?? '');
      final lng = double.tryParse(loc['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      final role = emp['role'] as String? ?? '';
      final color = _roleColors[role] ?? Colors.grey;
      final icon = _roleIcons[role] ?? Icons.person_pin;
      final isLive = emp['source'] == 'live';
      final isMoving = loc['is_moving'] as bool? ?? false;

      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 130,
        height: 60,
        child: GestureDetector(
          onTap: () => _showEmployeeDetail(emp),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                  border: Border.all(color: isLive ? Colors.green : Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive)
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                    if (isLive) const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        emp['name'] ?? '-',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: color, size: 26),
                  if (isMoving)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ));
    }
    return markers;
  }

  void _showEmployeeDetail(Map<String, dynamic> emp) {
    final loc = emp['location'] as Map<String, dynamic>? ?? {};
    final updatedAt = loc['updated_at'] as String? ?? '-';
    final speed = loc['speed'];
    final battery = loc['battery_level'];
    final isMoving = loc['is_moving'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_roleIcons[emp['role']] ?? Icons.person, color: _roleColors[emp['role']] ?? Colors.grey),
              const SizedBox(width: 8),
              Text(emp['name'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (emp['source'] == 'live' ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  emp['source'] == 'live' ? 'LIVE' : 'Terakhir Diketahui',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: emp['source'] == 'live' ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(_roleLabel(emp['role'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 20),
            _detailRow(Icons.access_time, 'Update', _formatTime(updatedAt)),
            _detailRow(Icons.speed, 'Kecepatan', speed != null ? '${(speed as num).toStringAsFixed(1)} m/s' : '-'),
            _detailRow(Icons.battery_std, 'Baterai', battery != null ? '$battery%' : '-'),
            _detailRow(Icons.directions_walk, 'Bergerak', isMoving ? 'Ya' : 'Tidak'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _loadHistoryForEmployee(emp);
                },
                icon: const Icon(Icons.route, size: 16),
                label: const Text('Lihat Riwayat Hari Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadHistoryForEmployee(Map<String, dynamic> emp) {
    // TODO: navigasi ke layar riwayat lokasi karyawan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Riwayat lokasi ${emp['name']} — segera hadir')),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _roleLabel(String role) {
    const labels = {
      'driver':          'Driver',
      'service_officer': 'Service Officer',
      'admin':           'Admin',
      'gudang':          'Gudang',
      'finance':         'Finance',
      'hrd':             'HRD',
      'dekor':           'Dekorator',
      'tukang_foto':     'Tukang Foto',
      'tukang_jaga':     'Tukang Jaga',
      'vendor':          'Vendor',
    };
    return labels[role] ?? role;
  }

  List<String> get _availableRoles {
    final roles = _employeeLocations.map((e) => e['role'] as String? ?? '').toSet().toList();
    roles.sort();
    return roles;
  }

  int get _liveCount => _employeeLocations.where((e) => e['source'] == 'live').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(title: 'Peta Karyawan', accentColor: _roleColor),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(
              initialCenter: LatLng(-6.9666, 110.4196),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.santamaria.funeral',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Stats overlay
          Positioned(
            top: 8, left: 8, right: 8,
            child: GlassWidget(
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Total Terlacak', _employeeLocations.length, Icons.people, _roleColor),
                        _stat('Live Sekarang', _liveCount, Icons.gps_fixed, Colors.green),
                        _stat('Bergerak', _employeeLocations.where((e) => (e['location'] as Map?)?['is_moving'] == true).length, Icons.directions_walk, Colors.orange),
                      ],
                    ),
                    if (_availableRoles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _roleChip('semua', 'Semua'),
                            ..._availableRoles.map((r) => _roleChip(r, _roleLabel(r))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: _roleColor,
        onPressed: _loadData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _roleChip(String role, String label) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _roleColor : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _roleColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
