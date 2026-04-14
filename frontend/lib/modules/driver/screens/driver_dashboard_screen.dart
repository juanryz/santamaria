import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/driver_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../auth/screens/unified_login_screen.dart';
import 'driver_trip_log_screen.dart';
import '../../attendance/screens/clock_in_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final DriverRepository _repo;
  final _api = ApiClient();

  bool _isLoading = true;
  bool _isOnDuty = false;
  bool _togglingDuty = false;
  Map<String, dynamic>? _activeOrder;

  final MapController _mapCtrl = MapController();
  LatLng _currentPos = LatLng(-6.2088, 106.8456);
  List<Marker> _markers = [];

  Timer? _locationTimer;

  static const _roleColor = AppColors.roleDriver;

  @override
  void initState() {
    super.initState();
    _repo = DriverRepository(ApiClient());
    _init();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkSession();
    await _loadOrders();
  }

  Future<void> _checkSession() async {
    try {
      final res = await _api.dio.get('/driver/session/active');
      if (res.data['success'] == true) {
        final isOnDuty = res.data['data']['is_on_duty'] == true;
        setState(() => _isOnDuty = isOnDuty);
        if (isOnDuty) _startLocationTracking();
      }
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getAssignments();
      if (res.data['success'] == true) {
        final orders = List<dynamic>.from(res.data['data'] ?? []);
        setState(() {
          _activeOrder = orders.isNotEmpty ? orders.first : null;
        });
        _updateMarkers();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    if (_activeOrder == null) return;
    final markers = <Marker>[];
    final lat = double.tryParse(_activeOrder!['pickup_lat']?.toString() ?? '');
    final lng = double.tryParse(_activeOrder!['pickup_lng']?.toString() ?? '');
    if (lat != null && lng != null) {
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 30,
        height: 30,
        child: const Icon(Icons.location_on, color: AppColors.statusWarning, size: 30),
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _toggleDuty() async {
    setState(() => _togglingDuty = true);
    try {
      if (_isOnDuty) {
        await _api.dio.post('/driver/session/end');
        _locationTimer?.cancel();
        setState(() => _isOnDuty = false);
        _snack('Sesi On Duty berakhir. Sampai jumpa!');
      } else {
        await _api.dio.post('/driver/session/start');
        setState(() => _isOnDuty = true);
        _startLocationTracking();
        _snack('Sesi On Duty dimulai. Lokasi Anda dipantau.');
      }
    } catch (_) {
      _snack('Gagal mengubah status On Duty.');
    } finally {
      if (mounted) setState(() => _togglingDuty = false);
    }
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _postLocation());
  }

  Future<void> _postLocation() async {
    try {
      await _api.dio.post('/driver/location', data: {
        'lat': _currentPos.latitude,
        'lng': _currentPos.longitude,
        'speed': 0,
        'heading': 0,
        'accuracy': 10,
        'recorded_at': DateTime.now().toIso8601String(),
        if (_activeOrder != null) 'order_id': _activeOrder!['id'],
      });
    } catch (_) {}
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      final res = await _repo.updateStatus(orderId, status);
      if (!mounted) return;
      if (res.data['success'] == true) {
        _loadOrders();
        _snack(_statusMsg(status));
      }
    } catch (_) {
      _snack('Gagal update status.');
    }
  }

  String _statusMsg(String s) => switch (s) {
        'on_the_way' => 'Status: Sedang menuju lokasi penjemputan.',
        'arrived_pickup' => 'Konfirmasi: Tiba di lokasi penjemputan.',
        'arrived_destination' => 'Konfirmasi: Tiba di tujuan.',
        'done' => 'Tugas selesai!',
        _ => 'Status diperbarui.',
      };

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            backgroundColor: Colors.green,
            heroTag: 'attendance',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClockInScreen())),
            child: const Icon(Icons.fingerprint, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            backgroundColor: _roleColor,
            heroTag: 'trip_log',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripLogScreen())),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _currentPos,
              initialZoom: 14,
              onTap: (tapPos, latLng) {
                setState(() => _currentPos = latLng);
                _mapCtrl.move(latLng, _mapCtrl.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.santamaria.funeral',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _currentPos,
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.my_location, color: AppColors.roleDriver, size: 24),
                ),
                ..._markers,
              ]),
            ],
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(user),
                const Spacer(),
                if (!_isLoading) ...[
                  _buildOnDutyCard(),
                  const SizedBox(height: 10),
                  if (_isOnDuty && _activeOrder != null)
                    _buildActiveOrderCard(_activeOrder!),
                  if (_isOnDuty && _activeOrder == null)
                    _buildNoOrderCard(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic>? user) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GlassWidget(
              borderRadius: 50,
              blurSigma: 20,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _roleColor,
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?['name'] ?? 'Driver',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnDuty
                                  ? AppColors.statusSuccess
                                  : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isOnDuty ? 'On Duty' : 'Off Duty',
                            style: TextStyle(
                              color: _isOnDuty
                                  ? AppColors.statusSuccess
                                  : AppColors.textHint,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            GlassWidget(
              borderRadius: 50,
              blurSigma: 20,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(8),
              onTap: () async {
                final nav = Navigator.of(context);
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const UnifiedLoginScreen()),
                  (_) => false,
                );
              },
              child: const Icon(Icons.logout,
                  color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      );

  Widget _buildOnDutyCard() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassWidget(
          borderRadius: 20,
          blurSigma: 20,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnDuty ? 'Sedang On Duty' : 'Mulai Bekerja',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOnDuty
                          ? 'Lokasi Anda sedang dipantau secara live.'
                          : 'Aktifkan On Duty untuk menerima tugas.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _togglingDuty
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: _toggleDuty,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: _isOnDuty
                              ? AppColors.statusSuccess
                              : AppColors.glassBorder,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          alignment: _isOnDuty
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final driverStatus = order['driver_status'] as String?;
    final next = _nextAction(driverStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassWidget(
        borderRadius: 20,
        blurSigma: 20,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('TUGAS AKTIF',
                      style: TextStyle(
                          color: _roleColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(order['order_number'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order['deceased_name'] ?? '-',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 6),
            _addrRow(Icons.location_on_outlined,
                order['pickup_address'] ?? '-', AppColors.statusWarning),
            const SizedBox(height: 4),
            _addrRow(Icons.flag_outlined,
                order['destination_address'] ?? '-', AppColors.statusSuccess),
            const SizedBox(height: 14),
            _buildProgress(driverStatus),
            if (next != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _updateStatus(order['id'], next.$1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: next.$2,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(next.$3,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addrRow(IconData icon, String text, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _buildProgress(String? status) {
    final steps = [
      ('on_the_way', 'Berangkat'),
      ('arrived_pickup', 'Tiba'),
      ('arrived_destination', 'Tujuan'),
      ('done', 'Selesai'),
    ];
    final idx = steps.indexWhere((s) => s.$1 == status);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < idx
                  ? AppColors.statusSuccess
                  : AppColors.glassBorder,
            ),
          );
        }
        final n = i ~/ 2;
        final done = n <= idx;
        return Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.statusSuccess : AppColors.glassBorder,
              ),
            ),
            const SizedBox(height: 2),
            Text(steps[n].$2,
                style: TextStyle(
                    color: done
                        ? AppColors.statusSuccess
                        : AppColors.textHint,
                    fontSize: 8)),
          ],
        );
      }),
    );
  }

  (String, Color, String)? _nextAction(String? current) => switch (current) {
        null || '' => (
            'on_the_way',
            AppColors.roleConsumer,
            'BERANGKAT SEKARANG'
          ),
        'on_the_way' => (
            'arrived_pickup',
            AppColors.statusWarning,
            'TIBA DI PENJEMPUTAN'
          ),
        'arrived_pickup' => (
            'arrived_destination',
            AppColors.roleSO,
            'TIBA DI TUJUAN'
          ),
        'arrived_destination' => (
            'done',
            AppColors.statusSuccess,
            'SELESAIKAN TUGAS'
          ),
        _ => null,
      };

  Widget _buildNoOrderCard() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassWidget(
          borderRadius: 20,
          blurSigma: 20,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(18),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.statusSuccess, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tidak ada tugas saat ini.',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold)),
                    Text('Lokasi Anda terus dipantau.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
