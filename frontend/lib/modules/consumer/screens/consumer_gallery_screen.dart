import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsumerGalleryScreen extends StatefulWidget {
  final String orderId;
  const ConsumerGalleryScreen({super.key, required this.orderId});

  @override
  State<ConsumerGalleryScreen> createState() => _ConsumerGalleryScreenState();
}

class _ConsumerGalleryScreenState extends State<ConsumerGalleryScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _media = [];
  Map<String, dynamic>? _obituary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/consumer/orders/${widget.orderId}/gallery'),
        _api.dio.get('/consumer/orders/${widget.orderId}/obituary'),
      ]);

      if (!mounted) return;

      if (results[0].data['success'] == true) {
        _media = List<dynamic>.from(results[0].data['data']['media'] ?? []);
      }
      if (results[1].data['success'] == true) {
        _obituary = results[1].data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat galeri.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Dokumentasi & Berita Duka',
        accentColor: AppColors.roleConsumer,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_obituary != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: _buildObituaryCard(),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: const Text(
                      'Galeri Foto & Video',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_media.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Belum ada dokumentasi diunggah oleh Staff.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _buildMediaTile(_media[i] as Map<String, dynamic>),
                        childCount: _media.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildObituaryCard() {
    final obit = _obituary!;
    final name = obit['deceased_name'] ?? 'Almarhum';
    final dod = obit['deceased_dod'];
    final religion = obit['deceased_religion'] ?? '-';
    final photoUrl = obit['photo_url'];

    String formattedDod = '-';
    if (dod != null) {
      try {
        final dt = DateTime.parse(dod);
        formattedDod = DateFormat('dd MMMM yyyy', 'id').format(dt);
      } catch (_) {}
    }

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'BERITA DUKA CITA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          if (photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                width: 140,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.account_box,
                  size: 80,
                  color: AppColors.textHint,
                ),
              ),
            )
          else
            Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_box,
                size: 64,
                color: AppColors.textHint,
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Telah berpulang ke Rumah Bapa di Surga,',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Pada tanggal $formattedDod',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.roleConsumer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Agama: $religion',
              style: const TextStyle(
                color: AppColors.roleConsumer,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Semoga amal ibadahnya diterima di sisi-Nya\ndan keluarga yang ditinggalkan diberikan ketabahan.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTile(Map<String, dynamic> m) {
    final isLink = m['file_type'] == 'link' || m['drive_link'] != null;
    final isVideo = (m['file_type'] as String? ?? '').startsWith('video/');
    final url = m['url'] as String?;
    final driveLink = m['drive_link'] as String?;

    return GestureDetector(
      onTap: () async {
        if (isLink && driveLink != null) {
          final uri = Uri.parse(driveLink);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        } else if (url != null && !isVideo) {
          // simple full screen image view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: Center(
                  child: InteractiveViewer(child: Image.network(url)),
                ),
              ),
            ),
          );
        }
      },
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: AppColors.backgroundSoft,
        borderColor: AppColors.glassBorder,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isLink
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_to_drive,
                      size: 48,
                      color: AppColors.roleConsumer,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buka Drive',
                      style: TextStyle(
                        color: AppColors.roleConsumer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        m['caption'] ?? 'Media Eksternal',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : isVideo
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.movie,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Video',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ],
                )
              : url != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(url, fit: BoxFit.cover),
                    if (m['caption'] != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            m['caption'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                )
              : const Icon(
                  Icons.image_not_supported,
                  color: AppColors.textHint,
                ),
        ),
      ),
    );
  }
}
