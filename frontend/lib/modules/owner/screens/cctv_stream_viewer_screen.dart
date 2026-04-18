import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.39 — CCTV live stream viewer.
///
/// Placeholder: actual RTSP playback memerlukan native player (flutter_vlc_player
/// atau media_kit). Untuk sekarang tampilkan stream URL + tombol copy untuk
/// playback via app eksternal (VLC, dll). Bisa di-upgrade ke embedded player
/// setelah dependency native ditambahkan ke pubspec.yaml.
class CctvStreamViewerScreen extends StatefulWidget {
  final String cameraId;
  final String cameraLabel;

  const CctvStreamViewerScreen({
    super.key,
    required this.cameraId,
    required this.cameraLabel,
  });

  @override
  State<CctvStreamViewerScreen> createState() => _CctvStreamViewerScreenState();
}

class _CctvStreamViewerScreenState extends State<CctvStreamViewerScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final res = await _api.dio.get('/owner/cctv/cameras/${widget.cameraId}/live');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() => _data = Map<String, dynamic>.from(res.data['data']));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat stream.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat stream kamera.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyUrl() async {
    if (_data?['stream_url'] == null) return;
    await Clipboard.setData(ClipboardData(text: _data!['stream_url']));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('URL stream disalin ke clipboard'),
          backgroundColor: AppColors.statusSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GlassAppBar(
        title: widget.cameraLabel,
        accentColor: AppColors.roleOwner,
        showBack: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _data == null
                  ? const Center(child: Text('-'))
                  : _buildViewer(),
    );
  }

  Widget _buildViewer() {
    final streamUrl = _data!['stream_url'] ?? '';
    final streamType = (_data!['stream_type'] ?? 'rtsp').toString().toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Placeholder video area
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.roleOwner, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam,
                      size: 48, color: AppColors.roleOwner),
                  const SizedBox(height: 12),
                  Text(streamType,
                      style: const TextStyle(
                          color: AppColors.roleOwner,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Embed player butuh native library',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  const Text('(flutter_vlc_player / media_kit)',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassWidget(
          padding: const EdgeInsets.all(14),
          tint: Colors.white.withOpacity(0.1),
          borderColor: Colors.white30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stream URL',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              SelectableText(streamUrl,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.roleOwner),
                      onPressed: _copyUrl,
                      icon: const Icon(Icons.copy),
                      label: const Text('Salin URL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Buka VLC Media Player → Media → Open Network Stream → '
                'paste URL untuk playback eksternal.',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _infoRow('Lokasi', _locationLabel(_data!['location_type'] ?? '-')),
        _infoRow('Area Detail', _data!['area_detail'] ?? '-'),
        _infoRow('Stream Type', streamType),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13)),
            ),
            Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  String _locationLabel(String t) => switch (t) {
        'kantor' => 'Kantor',
        'gudang' => 'Gudang',
        'lafiore' => 'Lafiore',
        'parkiran' => 'Parkiran',
        'pos_security' => 'Pos Security',
        _ => t,
      };

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusDanger),
              const SizedBox(height: 12),
              Text(_error ?? '',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Coba Lagi',
                    style: TextStyle(color: AppColors.roleOwner)),
              ),
            ],
          ),
        ),
      );
}
