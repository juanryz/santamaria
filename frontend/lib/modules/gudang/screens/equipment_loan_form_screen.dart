import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class EquipmentLoanFormScreen extends StatefulWidget {
  const EquipmentLoanFormScreen({super.key});

  @override
  State<EquipmentLoanFormScreen> createState() => _EquipmentLoanFormScreenState();
}

class _EquipmentLoanFormScreenState extends State<EquipmentLoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;

  final _namaAlmarhumCtrl = TextEditingController();
  final _rumahDukaCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  DateTime? _tglPeringatan;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tglPeringatan = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _tglPeringatan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua field wajib')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.dio.post('/gudang/equipment-loans', data: {
        'nama_almarhum': _namaAlmarhumCtrl.text,
        'rumah_duka': _rumahDukaCtrl.text.isNotEmpty ? _rumahDukaCtrl.text : null,
        'cp_almarhum': _cpCtrl.text.isNotEmpty ? _cpCtrl.text : null,
        'tgl_peringatan': _tglPeringatan!.toIso8601String().split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pinjaman dibuat')));
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
      appBar: GlassAppBar(title: 'Pinjaman Peralatan', accentColor: AppColors.roleGudang),
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
                      controller: _namaAlmarhumCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Almarhum *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rumahDukaCtrl,
                      decoration: const InputDecoration(labelText: 'Rumah Duka', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cpCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person Keluarga', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal Peringatan *', border: OutlineInputBorder()),
                        child: Text(_tglPeringatan != null
                            ? _tglPeringatan!.toIso8601String().split('T')[0]
                            : 'Pilih tanggal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.roleGudang, minimumSize: const Size.fromHeight(48)),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Buat Pinjaman Peralatan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaAlmarhumCtrl.dispose();
    _rumahDukaCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }
}
