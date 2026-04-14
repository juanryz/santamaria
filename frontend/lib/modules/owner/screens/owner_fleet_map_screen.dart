import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// Owner fleet real-time map — shows all active drivers with GPS positions.
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

  List<dynamic> _activeOrders = [];
  final Map<String, Map<String, dynamic>> _driverLocations = {};

  static const _roleColor = AppColors.roleOwner;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshLocations());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/owner/orders');
      if (res.data['success'] == true) {
        _activeOrders = List<dynamic>.from(res.data['data'] ?? [])
            .where((o) => o['driver_id'] != null && !['completed', 'cancelled'].contains(o['status']))
            .toList();
      }
      await _refreshLocations();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshLocations() async {
    for (final order in _activeOrders) {
      final driverId = order['driver_id'];
      if (driverId == null) continue;
      try {
        final res = await _api.dio.get('/driver/gps/latest/$driverId');
        if (res.data['success'] == true && res.data['data'] != null) {
          _driverLocations[driverId] = Map<String, dynamic>.from(res.data['data']);
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final order in _activeOrders) {
      final driverId = order['driver_id'] as String?;
      if (driverId == null) continue;
      final loc = _driverLocations[driverId];
      if (loc == null) continue;

      final lat = double.tryParse(loc['latitude']?.toString() ?? '');
      final lng = double.tryParse(loc['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 50,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
              ),
              child: Text(
                order['driver']?['name'] ?? 'Driver',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.directions_car, color: AppColors.roleDriver, size: 24),
          ],
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(title: 'Peta Armada', accentColor: _roleColor),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: LatLng(-6.9666, 110.4196), // Semarang
              initialZoom: 12,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.santamaria.funeral'),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          // Stats overlay
          Positioned(
            top: 8, left: 8, right: 8,
            child: GlassWidget(
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Order Aktif', _activeOrders.length, Icons.assignment, _roleColor),
                    _stat('Driver Terlacak', _driverLocations.length, Icons.gps_fixed, Colors.green),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
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
