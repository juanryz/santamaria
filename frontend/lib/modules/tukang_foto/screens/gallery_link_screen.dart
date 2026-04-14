import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class GalleryLinkScreen extends StatefulWidget {
  final String orderId;
  final bool canAdd; // true for tukang_foto, false for consumer/SO
  const GalleryLinkScreen({super.key, required this.orderId, this.canAdd = false});

  @override
  State<GalleryLinkScreen> createState() => _GalleryLinkScreenState();
}

class _GalleryLinkScreenState extends State<GalleryLinkScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _links = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefix = widget.canAdd ? '/tukang-foto' : '';
      final res = await _api.dio.get('$prefix/orders/${widget.orderId}/gallery-links');
      if (res.data['success'] == true) {
        _links = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addLink() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Link Google Drive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul *', hintText: 'Contoh: Foto Prosesi Hari 1', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Link Google Drive *', hintText: 'https://drive.google.com/...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)), keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Simpan Link'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.roleTukangFoto, minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
      try {
        await _api.dio.post('/tukang-foto/orders/${widget.orderId}/gallery-links', data: {
          'title': titleCtrl.text,
          'drive_url': urlCtrl.text,
          'description': descCtrl.text.isNotEmpty ? descCtrl.text : null,
        });
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link berhasil ditambahkan')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteLink(String id) async {
    try {
      await _api.dio.delete('/tukang-foto/orders/${widget.orderId}/gallery-links/$id');
      _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Link Galeri Foto', accentColor: AppColors.roleTukangFoto),
      floatingActionButton: widget.canAdd
          ? FloatingActionButton.extended(
              onPressed: _addLink,
              backgroundColor: AppColors.roleTukangFoto,
              icon: const Icon(Icons.add_link, color: Colors.white),
              label: const Text('Tambah Link', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _links.isEmpty
                ? const Center(child: Text('Belum ada link galeri'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _links.length,
                    itemBuilder: (_, i) {
                      final link = _links[i];
                      final isGDrive = link['link_type'] == 'google_drive';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 16,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openLink(link['drive_url'] ?? ''),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isGDrive
                                          ? const Color(0xFF4285F4).withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      isGDrive ? Icons.add_to_drive : Icons.link,
                                      color: isGDrive ? const Color(0xFF4285F4) : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(link['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (link['description'] != null)
                                          Text(link['description'], style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Oleh: ${link['uploader']?['name'] ?? '-'}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      const Icon(Icons.open_in_new, color: Color(0xFF4285F4), size: 20),
                                      if (widget.canAdd)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          onPressed: () => _deleteLink(link['id']),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
