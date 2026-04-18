import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'cctv_stream_viewer_screen.dart';

/// v1.39 — Owner monitoring CCTV live feed.
/// Grid view per lokasi (kantor/gudang/lafiore/parkiran/pos_security).
class CctvMonitoringScreen extends StatefulWidget {
  const CctvMonitoringScreen({super.key});

  @override
  State<CctvMonitoringScreen> createState() => _CctvMonitoringScreenState();
}

class _CctvMonitoringScreenState extends State<CctvMonitoringScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/owner/cctv/cameras', queryParameters: {
        if (_filter != 'all') 'location': _filter,
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _data = Map<String, dynamic>.from(res.data['data']));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat kamera.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat kamera CCTV.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _data['total'] ?? 0;
    final byLocation = _data['by_location'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'CCTV Monitoring',
        accentColor: AppColors.roleOwner,
        showBack: true,
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator()
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.roleOwner.withOpacity(0.08),
                borderColor: AppColors.roleOwner.withOpacity(0.2),
                child: Row(
                  children: [
                    const Icon(Icons.videocam,
                        color: AppColors.roleOwner, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$total Kamera Aktif',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text('${byLocation.length} lokasi terpantau',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Semua', 'all'),
                _chip('Kantor', 'kantor'),
                _chip('Gudang', 'gudang'),
                _chip('Lafiore', 'lafiore'),
                _chip('Parkiran', 'parkiran'),
                _chip('Pos Security', 'pos_security'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? _buildError()
                  : byLocation.isEmpty
                      ? _buildEmpty()
                      : _buildContent(byLocation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppColors.roleOwner.withOpacity(0.15),
        labelStyle: TextStyle(
            color: selected ? AppColors.roleOwner : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.videocam_off_outlined,
        title: 'Belum Ada Kamera',
        subtitle: 'Hubungi Super Admin untuk menambahkan kamera CCTV.',
      );

  Widget _buildContent(Map<String, dynamic> byLocation) {
    final entries = byLocation.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: entries.length,
      itemBuilder: (c, i) {
        final key = entries[i].key;
        final cameras = List<dynamic>.from(entries[i].value ?? []);
        return _locationSection(key, cameras);
      },
    );
  }

  Widget _locationSection(String locationType, List<dynamic> cameras) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(_locationIcon(locationType),
                  size: 18, color: AppColors.roleOwner),
              const SizedBox(width: 8),
              Text(_locationLabel(locationType),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 6),
              GlassStatusBadge(
                  label: '${cameras.length}',
                  color: AppColors.brandSecondary),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: cameras.length,
          itemBuilder: (c, i) =>
              _cameraCard(cameras[i] as Map<String, dynamic>),
        ),
      ],
    );
  }

  Widget _cameraCard(Map<String, dynamic> cam) {
    final isActive = cam['is_active'] == true;
    return GlassWidget(
      padding: const EdgeInsets.all(12),
      borderColor: (isActive ? AppColors.statusSuccess : AppColors.textHint)
          .withOpacity(0.3),
      onTap: isActive
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CctvStreamViewerScreen(
                    cameraId: cam['id'],
                    cameraLabel: cam['camera_label'] ?? '-',
                  ),
                ),
              )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam,
                  color: isActive
                      ? AppColors.statusSuccess
                      : AppColors.textHint,
                  size: 18),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.statusSuccess
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(cam['camera_label'] ?? '-',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if ((cam['area_detail'] ?? '').toString().isNotEmpty)
            Text(cam['area_detail'],
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('IP: ${cam['ip_address']}',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  IconData _locationIcon(String t) => switch (t) {
        'kantor' => Icons.business,
        'gudang' => Icons.warehouse,
        'lafiore' => Icons.local_florist,
        'parkiran' => Icons.local_parking,
        'pos_security' => Icons.security,
        _ => Icons.place,
      };

  String _locationLabel(String t) => switch (t) {
        'kantor' => 'Kantor',
        'gudang' => 'Gudang',
        'lafiore' => 'Lafiore',
        'parkiran' => 'Parkiran',
        'pos_security' => 'Pos Security',
        _ => t,
      };

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
                  onPressed: _load, child: const Text('Coba Lagi'))),
        ],
      );
}
