import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

/// Consumer signs Terms & Conditions — Surat Penerimaan Layanan.
class ConsumerAcceptanceScreen extends StatefulWidget {
  final String orderId;
  const ConsumerAcceptanceScreen({super.key, required this.orderId});

  @override
  State<ConsumerAcceptanceScreen> createState() => _ConsumerAcceptanceScreenState();
}

class _ConsumerAcceptanceScreenState extends State<ConsumerAcceptanceScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _agreed = false;
  Map<String, dynamic>? _data;
  static const _roleColor = AppColors.roleConsumer;

  final _nameCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/consumer/orders/${widget.orderId}/acceptance');
      if (res.data['success'] == true) {
        _data = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sign() async {
    if (!_agreed || _nameCtrl.text.isEmpty || _relationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Centang persetujuan dan isi nama lengkap')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.dio.post('/consumer/orders/${widget.orderId}/acceptance/sign', data: {
        'agreed': true,
        'pj_name': _nameCtrl.text,
        'pj_relation': _relationCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat Penerimaan berhasil ditandatangani')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Surat Penerimaan Layanan', accentColor: _roleColor),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Data tidak tersedia'))
              : _data!['already_signed'] == true
                  ? _buildAlreadySigned()
                  : _buildForm(),
    );
  }

  Widget _buildAlreadySigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text('Surat Penerimaan Sudah Ditandatangani', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final order = _data!['order'] as Map<String, dynamic>? ?? {};
    final terms = _data!['terms'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Order summary
        GlassWidget(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order: ${order['order_number'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Almarhum: ${order['deceased_name'] ?? '-'}'),
                Text('Paket: ${order['package_name'] ?? '-'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Terms & Conditions
        if (terms != null) ...[
          GlassWidget(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(terms['title'] ?? 'Syarat & Ketentuan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Versi ${terms['version']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Text(terms['content'] ?? '', style: const TextStyle(fontSize: 13, height: 1.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Signature form
        GlassWidget(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Penanggung Jawab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _relationCtrl,
                  decoration: const InputDecoration(labelText: 'Hubungan dgn Almarhum *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _agreed,
                  activeColor: _roleColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  title: const Text(
                    'Saya menyetujui Syarat & Ketentuan dan menerima layanan pemakaman dari Santa Maria Funeral Organizer.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: (_agreed && !_isSubmitting) ? _sign : null,
          style: FilledButton.styleFrom(
            backgroundColor: _roleColor,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Tanda Tangan & Setuju', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }
}
