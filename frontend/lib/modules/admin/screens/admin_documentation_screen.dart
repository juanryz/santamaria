import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminDocumentationScreen extends StatefulWidget {
  const AdminDocumentationScreen({super.key});

  @override
  State<AdminDocumentationScreen> createState() =>
      _AdminDocumentationScreenState();
}

class _AdminDocumentationScreenState extends State<AdminDocumentationScreen> {
  final _api = ApiClient();
  final _searchCtrl = TextEditingController();
  List<dynamic> _orders = [];
  bool _isLoading = true;

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/admin/documentation/orders',
        queryParameters: search.isNotEmpty ? {'search': search} : null,
      );
      if (res.data['success'] == true && mounted) {
        final raw = res.data['data'];
        final list = raw is Map ? raw['data'] : raw;
        setState(() => _orders = List<dynamic>.from(list ?? []));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Dokumentasi Pasca Acara',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nomor order / nama almarhum...',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => _load(v.trim()),
              onChanged: (v) {
                if (v.isEmpty) _load();
                setState(() {}); // refresh suffix icon
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada order ditemukan.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _buildOrderCard(
                              _orders[i] as Map<String, dynamic>,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final mediaCount = order['staff_media_count'] as int? ?? 0;
    final isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 18,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: mediaCount > 0
            ? AppColors.statusSuccess.withValues(alpha: 0.2)
            : AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _OrderDocumentationScreen(orderId: order['id'] as String),
          ),
        ).then((_) => _load(_searchCtrl.text.trim())),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['order_number'] ?? '-',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order['deceased_name'] ?? '-',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (order['pic'] as Map?)?['name'] ?? '-',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isCompleted
                                ? AppColors.statusSuccess
                                : AppColors.roleConsumer)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Selesai' : 'Berjalan',
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.statusSuccess
                          : AppColors.roleConsumer,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      mediaCount > 0
                          ? Icons.photo_library_outlined
                          : Icons.photo_library_outlined,
                      size: 13,
                      color: mediaCount > 0
                          ? AppColors.statusSuccess
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$mediaCount media',
                      style: TextStyle(
                        color: mediaCount > 0
                            ? AppColors.statusSuccess
                            : AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail & Upload Dokumentasi ──────────────────────────────────────────────

class _OrderDocumentationScreen extends StatefulWidget {
  final String orderId;
  const _OrderDocumentationScreen({required this.orderId});

  @override
  State<_OrderDocumentationScreen> createState() =>
      _OrderDocumentationScreenState();
}

class _OrderDocumentationScreenState extends State<_OrderDocumentationScreen> {
  final _api = ApiClient();
  final _picker = ImagePicker();
  Map<String, dynamic>? _order;
  List<dynamic> _media = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/admin/documentation/orders/${widget.orderId}',
      );
      if (res.data['success'] == true && mounted) {
        setState(() {
          _order = res.data['data']['order'] as Map<String, dynamic>;
          _media = List<dynamic>.from(res.data['data']['media'] ?? []);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat data.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = picked.length;
    });

    final messenger = ScaffoldMessenger.of(context);
    int successCount = 0;

    try {
      // Build multipart form data with all files
      final formData = FormData();
      for (final xf in picked) {
        formData.files.add(
          MapEntry(
            'photos[]',
            await MultipartFile.fromFile(xf.path, filename: xf.name),
          ),
        );
      }
      formData.fields.add(const MapEntry('category', 'dokumentasi'));

      await _api.dio.post(
        '/admin/documentation/orders/${widget.orderId}/photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(
              () => _uploadProgress = ((sent / total) * picked.length)
                  .round()
                  .clamp(0, picked.length),
            );
          }
        },
      );
      successCount = picked.length;
    } catch (_) {
      // Try one-by-one as fallback
      for (int i = 0; i < picked.length; i++) {
        try {
          final xf = picked[i];
          final fd = FormData.fromMap({
            'photos[]': await MultipartFile.fromFile(
              xf.path,
              filename: xf.name,
            ),
            'category': 'dokumentasi',
          });
          await _api.dio.post(
            '/admin/documentation/orders/${widget.orderId}/photos',
            data: fd,
            options: Options(contentType: 'multipart/form-data'),
          );
          successCount++;
        } catch (_) {}
        if (mounted) setState(() => _uploadProgress = i + 1);
      }
    }

    if (!mounted) return;
    setState(() => _isUploading = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$successCount dari ${picked.length} foto berhasil diunggah.',
        ),
      ),
    );
    _load();
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTotal = 1;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final formData = FormData.fromMap({
        'photos[]': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
        'category': 'dokumentasi',
      });
      await _api.dio.post(
        '/admin/documentation/orders/${widget.orderId}/photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = ((sent / total) * 100).round());
          }
        },
      );
      if (!mounted) return;
      setState(() => _isUploading = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Video berhasil diunggah.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal upload video: $e')));
    }
  }

  void _showDriveLinkDialog() {
    final ctrl = TextEditingController();
    final captionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSoft,
        title: const Text(
          'Lampirkan Google Drive / Link',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'URL Google Drive / YouTube *',
                hintText: 'https://drive.google.com/...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: captionCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _api.dio.post(
                  '/admin/documentation/orders/${widget.orderId}/drive-link',
                  data: {
                    'drive_link': url,
                    'caption': captionCtrl.text.trim().isEmpty
                        ? null
                        : captionCtrl.text.trim(),
                  },
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Link berhasil dilampirkan.')),
                );
                _load();
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedia(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Media?'),
        content: const Text('Media ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.dio.delete('/admin/documentation/photos/$photoId');
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus media.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNum = _order?['order_number'] ?? '...';
    final deceasedName = _order?['deceased_name'] ?? '...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Dokumentasi · $orderNum',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order info card
                        GlassWidget(
                          borderRadius: 16,
                          blurSigma: 10,
                          tint: _roleColor.withValues(alpha: 0.06),
                          borderColor: _roleColor.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderNum,
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deceasedName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              if (_order?['pic'] != null)
                                Text(
                                  'PIC: ${(_order!['pic'] as Map?)!['name'] ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Upload progress
                        if (_isUploading) ...[
                          GlassWidget(
                            borderRadius: 14,
                            blurSigma: 10,
                            tint: _roleColor.withValues(alpha: 0.08),
                            borderColor: _roleColor.withValues(alpha: 0.2),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mengunggah $_uploadProgress / $_uploadTotal file...',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _uploadTotal > 0
                                      ? _uploadProgress / _uploadTotal
                                      : null,
                                  color: _roleColor,
                                  backgroundColor: _roleColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                Icons.photo_library_outlined,
                                'Upload Foto',
                                _isUploading ? null : _pickAndUpload,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                Icons.videocam_outlined,
                                'Upload Video',
                                _isUploading ? null : _pickVideo,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                Icons.link_outlined,
                                'Google Drive',
                                _isUploading ? null : _showDriveLinkDialog,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          '${_media.length} Media Diunggah',
                          style: const TextStyle(
                            color: _roleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // Media grid
                if (_media.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 56,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada media diunggah.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Upload foto/video atau lampirkan link Google Drive.',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _buildMediaTile(_media[i] as Map<String, dynamic>),
                        childCount: _media.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _roleColor,
          side: BorderSide(color: _roleColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );

  Widget _buildMediaTile(Map<String, dynamic> m) {
    final isLink = m['file_type'] == 'link' || m['drive_link'] != null;
    final isVideo = (m['file_type'] as String? ?? '').startsWith('video/');
    final url = m['url'] as String?;

    return Stack(
      fit: StackFit.expand,
      children: [
        GlassWidget(
          borderRadius: 12,
          blurSigma: 8,
          tint: AppColors.backgroundSoft,
          borderColor: AppColors.glassBorder,
          child: isLink
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.link,
                      color: AppColors.roleConsumer,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        m['caption'] ?? 'Drive Link',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : isVideo
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                    Text(
                      m['file_name'] ?? 'Video',
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 9,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image,
                      color: AppColors.textHint,
                    ),
                  ),
                )
              : const Icon(
                  Icons.image_not_supported,
                  color: AppColors.textHint,
                ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deleteMedia(m['id'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.statusDanger,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
