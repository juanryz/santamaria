import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SoDeathCertScreen extends StatefulWidget {
  final String orderId;
  final String namaAlmarhum;
  const SoDeathCertScreen({super.key, required this.orderId, required this.namaAlmarhum});

  @override
  State<SoDeathCertScreen> createState() => _SoDeathCertScreenState();
}

class _SoDeathCertScreenState extends State<SoDeathCertScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _doc;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/so/orders/${widget.orderId}/death-cert-docs');
      if (res.data['success'] == true && res.data['data'] != null) {
        _doc = Map<String, dynamic>.from(res.data['data']);
        _items = List<dynamic>.from(_doc?['items'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createChecklist() async {
    try {
      await _api.dio.post('/so/orders/${widget.orderId}/death-cert-docs', data: {
        'nama_almarhum': widget.namaAlmarhum,
      });
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _toggleItem(dynamic item, String field, bool value) async {
    try {
      await _api.dio.put('/so/orders/${widget.orderId}/death-cert-docs', data: {
        'items': [
          {'id': item['id'], field: value},
        ],
      });
      _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Berkas Akta Kematian', accentColor: AppColors.roleSO),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doc == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Belum ada checklist dokumen'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _createChecklist,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.roleSO),
                        child: const Text('Buat Checklist'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassWidget(
                      borderRadius: 16,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Almarhum: ${_doc?['nama_almarhum'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const SizedBox(width: 200),
                                const Expanded(child: Text('SM', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                const Expanded(child: Text('Keluarga', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._items.map((item) {
                      final docName = item['doc_master']?['doc_name'] ?? '-';
                      final isRequired = item['doc_master']?['is_required'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GlassWidget(
                          borderRadius: 10,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    docName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Checkbox(
                                    value: item['diterima_sm'] == true,
                                    activeColor: AppColors.roleSO,
                                    onChanged: (v) => _toggleItem(item, 'diterima_sm', v ?? false),
                                  ),
                                ),
                                Expanded(
                                  child: Checkbox(
                                    value: item['diterima_keluarga'] == true,
                                    activeColor: Colors.green,
                                    onChanged: (v) => _toggleItem(item, 'diterima_keluarga', v ?? false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
