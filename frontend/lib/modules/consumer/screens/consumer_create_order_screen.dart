import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class ConsumerCreateOrderScreen extends StatefulWidget {
  /// Pre-fill fields when coming from AI chatbot extraction.
  final Map<String, dynamic>? prefill;
  const ConsumerCreateOrderScreen({super.key, this.prefill});

  @override
  State<ConsumerCreateOrderScreen> createState() =>
      _ConsumerCreateOrderScreenState();
}

class _ConsumerCreateOrderScreenState
    extends State<ConsumerCreateOrderScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int _step = 0; // 0=PIC, 1=Almarhum, 2=Konfirmasi

  // PIC fields
  final _picNameCtrl = TextEditingController();
  final _picPhoneCtrl = TextEditingController();
  final _picAddressCtrl = TextEditingController();
  String _picRelation = 'anak';

  // Almarhum fields
  final _deceasedNameCtrl = TextEditingController();
  DateTime? _deceasedDod;
  String _deceasedReligion = 'kristen';
  final _pickupAddressCtrl = TextEditingController();
  final _destinationAddressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _relations = [
    ('anak', 'Anak'),
    ('suami_istri', 'Suami / Istri'),
    ('orang_tua', 'Orang Tua'),
    ('saudara', 'Saudara'),
    ('lainnya', 'Lainnya'),
  ];

  static const _religions = [
    ('islam', 'Islam'),
    ('kristen', 'Kristen'),
    ('katolik', 'Katolik'),
    ('hindu', 'Hindu'),
    ('buddha', 'Buddha'),
    ('konghucu', 'Konghucu'),
  ];

  @override
  void initState() {
    super.initState();
    _applyPrefill();
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    _picNameCtrl.text = p['pic_name'] ?? '';
    _picPhoneCtrl.text = p['pic_phone'] ?? '';
    _picAddressCtrl.text = p['pic_address'] ?? '';
    _deceasedNameCtrl.text = p['deceased_name'] ?? '';
    _pickupAddressCtrl.text = p['pickup_address'] ?? '';
    _destinationAddressCtrl.text = p['destination_address'] ?? '';
    if (p['pic_relation'] != null) _picRelation = p['pic_relation'];
    if (p['deceased_religion'] != null) _deceasedReligion = p['deceased_religion'];
    if (p['deceased_dod'] != null) {
      _deceasedDod = DateTime.tryParse(p['deceased_dod']);
    }
  }

  @override
  void dispose() {
    _picNameCtrl.dispose();
    _picPhoneCtrl.dispose();
    _picAddressCtrl.dispose();
    _deceasedNameCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _destinationAddressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deceasedDod == null) {
      _snack('Pilih tanggal meninggal almarhum.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await _api.dio.post('/consumer/orders', data: {
        'pic_name': _picNameCtrl.text.trim(),
        'pic_phone': _picPhoneCtrl.text.trim(),
        'pic_relation': _picRelation,
        'pic_address': _picAddressCtrl.text.trim(),
        'deceased_name': _deceasedNameCtrl.text.trim(),
        'deceased_dod': DateFormat('yyyy-MM-dd').format(_deceasedDod!),
        'deceased_religion': _deceasedReligion,
        'pickup_address': _pickupAddressCtrl.text.trim(),
        'destination_address': _destinationAddressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order berhasil dibuat. Service Officer akan segera menghubungi Anda.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
        Navigator.pop(context, true);
      } else {
        _snack(res.data['message'] ?? 'Gagal membuat order.');
      }
    } catch (_) {
      _snack('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _nextStep() {
    if (_step == 0 && !_validateStep0()) return;
    if (_step < 2) setState(() => _step++);
  }

  bool _validateStep0() {
    if (_picNameCtrl.text.trim().isEmpty) { _snack('Masukkan nama PIC.'); return false; }
    if (_picPhoneCtrl.text.trim().isEmpty) { _snack('Masukkan nomor HP PIC.'); return false; }
    if (_picAddressCtrl.text.trim().isEmpty) { _snack('Masukkan alamat PIC.'); return false; }
    return true;
  }

  bool _validateStep1() {
    if (_deceasedNameCtrl.text.trim().isEmpty) { _snack('Masukkan nama almarhum.'); return false; }
    if (_deceasedDod == null) { _snack('Pilih tanggal meninggal.'); return false; }
    if (_pickupAddressCtrl.text.trim().isEmpty) { _snack('Masukkan alamat penjemputan.'); return false; }
    if (_destinationAddressCtrl.text.trim().isEmpty) { _snack('Masukkan alamat tujuan.'); return false; }
    return true;
  }

  void _prevStep() { if (_step > 0) setState(() => _step--); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Buat Order Baru',
        accentColor: AppColors.roleConsumer,
        showBack: true,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['PIC', 'Almarhum', 'Konfirmasi'];
    return Container(
      color: AppColors.backgroundSoft,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < _step
                    ? AppColors.roleConsumer
                    : AppColors.textHint.withValues(alpha: 0.3),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _step;
          final active = idx == _step;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.roleConsumer
                      : active
                          ? AppColors.roleConsumer.withValues(alpha: 0.15)
                          : AppColors.backgroundSoft,
                  border: active
                      ? Border.all(color: AppColors.roleConsumer, width: 2)
                      : done
                          ? null
                          : Border.all(
                              color: AppColors.textHint.withValues(alpha: 0.4),
                              width: 1),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${idx + 1}',
                          style: TextStyle(
                            color: active
                                ? AppColors.roleConsumer
                                : AppColors.textHint,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[idx],
                  style: TextStyle(
                      color: active
                          ? AppColors.roleConsumer
                          : AppColors.textHint,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      0 => _buildStep0(key: const ValueKey(0)),
      1 => _buildStep1(key: const ValueKey(1)),
      _ => _buildStep2(key: const ValueKey(2)),
    };
  }

  Widget _buildStep0({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Data Penanggung Jawab (PIC)'),
            const SizedBox(height: 4),
            const Text('Orang yang bertanggung jawab atas pelayanan ini.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(height: 20),
            _field(controller: _picNameCtrl, label: 'Nama Lengkap PIC', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _field(controller: _picPhoneCtrl, label: 'Nomor HP PIC', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _dropdown<String>(
              label: 'Hubungan dengan Almarhum',
              value: _picRelation,
              items: _relations.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
              onChanged: (v) => setState(() => _picRelation = v!),
            ),
            const SizedBox(height: 14),
            _field(controller: _picAddressCtrl, label: 'Alamat PIC', icon: Icons.home_outlined, maxLines: 3),
          ],
        ),
      );

  Widget _buildStep1({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Data Almarhum'),
            const SizedBox(height: 20),
            _field(controller: _deceasedNameCtrl, label: 'Nama Almarhum / Almarhumah', icon: Icons.person_outline),
            const SizedBox(height: 14),
            // Date of death picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _deceasedDod = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.textHint.withValues(alpha: 0.5), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textHint, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _deceasedDod != null
                          ? DateFormat('d MMMM yyyy', 'id').format(_deceasedDod!)
                          : 'Tanggal Meninggal',
                      style: TextStyle(
                        color: _deceasedDod != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _dropdown<String>(
              label: 'Agama',
              value: _deceasedReligion,
              items: _religions.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
              onChanged: (v) => setState(() => _deceasedReligion = v!),
            ),
            const SizedBox(height: 14),
            _field(controller: _pickupAddressCtrl, label: 'Alamat Penjemputan', icon: Icons.location_on_outlined, maxLines: 3),
            const SizedBox(height: 14),
            _field(controller: _destinationAddressCtrl, label: 'Alamat Tujuan / Pemakaman', icon: Icons.flag_outlined, maxLines: 3),
            const SizedBox(height: 14),
            _field(controller: _notesCtrl, label: 'Catatan Tambahan (opsional)', icon: Icons.notes_outlined, maxLines: 3),
          ],
        ),
      );

  Widget _buildStep2({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Konfirmasi Data'),
            const SizedBox(height: 4),
            const Text('Pastikan data sudah benar sebelum mengirim.',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(height: 20),
            _confirmCard(
              label: 'PENANGGUNG JAWAB',
              rows: [
                ('Nama', _picNameCtrl.text),
                ('Nomor HP', _picPhoneCtrl.text),
                ('Hubungan', _relations.firstWhere((r) => r.$1 == _picRelation).$2),
                ('Alamat', _picAddressCtrl.text),
              ],
            ),
            const SizedBox(height: 14),
            _confirmCard(
              label: 'ALMARHUM / ALMARHUMAH',
              rows: [
                ('Nama', _deceasedNameCtrl.text),
                ('Tanggal Meninggal',
                    _deceasedDod != null
                        ? DateFormat('d MMMM yyyy', 'id').format(_deceasedDod!)
                        : '-'),
                ('Agama', _religions.firstWhere((r) => r.$1 == _deceasedReligion).$2),
                ('Penjemputan', _pickupAddressCtrl.text),
                ('Tujuan', _destinationAddressCtrl.text),
                if (_notesCtrl.text.isNotEmpty) ('Catatan', _notesCtrl.text),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.statusWarning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.statusWarning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Setelah order dikirim, Service Officer kami akan segera menghubungi Anda untuk konfirmasi dan pemilihan paket layanan.',
                      style: TextStyle(
                          color: AppColors.statusWarning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomBar() {
    return Container(
      color: AppColors.backgroundSoft,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text('Kembali'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_step == 1 && !_validateStep1()) return;
                      if (_step < 2) {
                        _nextStep();
                      } else {
                        _submit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _step == 2
                    ? AppColors.statusSuccess
                    : AppColors.roleConsumer,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_step == 2 ? 'KIRIM ORDER' : 'LANJUT'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18));

  Widget _confirmCard({
    required String label,
    required List<(String, String)> rows,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.roleConsumer,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(r.$1,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(
                          r.$2.isNotEmpty ? r.$2 : '-',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
          labelText: label,
        ),
      );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: value,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
      );
}
