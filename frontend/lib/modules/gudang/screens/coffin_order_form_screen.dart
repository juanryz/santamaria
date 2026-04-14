import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class CoffinOrderFormScreen extends StatefulWidget {
  const CoffinOrderFormScreen({super.key});

  @override
  State<CoffinOrderFormScreen> createState() => _CoffinOrderFormScreenState();
}

class _CoffinOrderFormScreenState extends State<CoffinOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;

  final _kodePetiCtrl = TextEditingController();
  final _ukuranCtrl = TextEditingController();
  final _warnaCtrl = TextEditingController();
  final _namaPemesanCtrl = TextEditingController();
  String _finishingType = 'melamin';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await _api.dio.post('/gudang/coffin-orders', data: {
        'kode_peti': _kodePetiCtrl.text,
        'finishing_type': _finishingType,
        'ukuran': _ukuranCtrl.text.isNotEmpty ? _ukuranCtrl.text : null,
        'warna': _warnaCtrl.text.isNotEmpty ? _warnaCtrl.text : null,
        'nama_pemesan': _namaPemesanCtrl.text.isNotEmpty ? _namaPemesanCtrl.text : null,
      });

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order peti dibuat')));
        Navigator.pop(context);
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
      appBar: GlassAppBar(title: 'Order Peti Baru', accentColor: AppColors.roleGudang),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassWidget(
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _kodePetiCtrl,
                      decoration: const InputDecoration(labelText: 'Kode Peti *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _finishingType,
                      decoration: const InputDecoration(labelText: 'Tipe Finishing *', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'melamin', child: Text('Melamin')),
                        DropdownMenuItem(value: 'duco', child: Text('Duco')),
                        DropdownMenuItem(value: 'natural', child: Text('Natural')),
                      ],
                      onChanged: (v) => setState(() => _finishingType = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ukuranCtrl,
                      decoration: const InputDecoration(labelText: 'Ukuran (P x L x T cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _warnaCtrl,
                      decoration: const InputDecoration(labelText: 'Warna', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaPemesanCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pemesan', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.roleGudang,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Buat Order Peti'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kodePetiCtrl.dispose();
    _ukuranCtrl.dispose();
    _warnaCtrl.dispose();
    _namaPemesanCtrl.dispose();
    super.dispose();
  }
}
