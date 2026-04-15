import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class SOCreateOrderScreen extends StatefulWidget {
  final SORepository repo;
  const SOCreateOrderScreen({super.key, required this.repo});

  @override
  State<SOCreateOrderScreen> createState() => _SOCreateOrderScreenState();
}

class _SOCreateOrderScreenState extends State<SOCreateOrderScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1 form ──────────────────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();

  // PIC (sama seperti form consumer)
  final _picNameController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _picAddressController = TextEditingController();
  String _picRelation = 'anak';

  final _deceasedNameController = TextEditingController();
  DateTime? _deceasedDob;
  DateTime _deceasedDod = DateTime.now();
  String _religion = 'kristen';
  final _dukaAddressController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  String? _selectedPackageId;
  Map<String, dynamic>? _selectedPackage;
  final List<String> _selectedAddonIds = [];
  final _soNotesController = TextEditingController();
  final _estimatedGuestsController = TextEditingController();
  DateTime? _scheduledAt;
  final _durationController = TextEditingController(text: '3');
  final _finalPriceController = TextEditingController();
  String _paymentMethod = 'cash'; // 'cash' | 'transfer'

  List<dynamic> _packages = [];
  List<dynamic> _addons = [];
  bool _isLoadingPackages = true;

  // ── Step 2 — SAL ─────────────────────────────────────────────────────────────
  final _step2Key = GlobalKey<FormState>();
  final _pjNameController = TextEditingController();
  final _officerNameController = TextEditingController();
  final _sigPJKey = GlobalKey<_SignaturePadState>();
  final _sigOfficerKey = GlobalKey<_SignaturePadState>();

  // ── Misc ─────────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  static const _roleColor = AppColors.roleSO;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    // Pre-fill officer name from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      _officerNameController.text = user?['name'] as String? ?? '';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _picNameController.dispose();
    _picPhoneController.dispose();
    _picAddressController.dispose();
    _deceasedNameController.dispose();
    _dukaAddressController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    _soNotesController.dispose();
    _estimatedGuestsController.dispose();
    _durationController.dispose();
    _finalPriceController.dispose();
    _pjNameController.dispose();
    _officerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.repo.getPackages(),
        widget.repo.getAddOns(),
      ]);
      if (results[0].data['success'] == true) {
        setState(() => _packages = results[0].data['data'] as List);
      }
      if (results[1].data['success'] == true) {
        setState(() => _addons = results[1].data['data'] as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPackages = false);
  }

  void _recalcPrice() {
    double total = 0;
    if (_selectedPackage != null) {
      total += double.tryParse(_selectedPackage!['base_price'].toString()) ?? 0;
    }
    for (final id in _selectedAddonIds) {
      final addon = _addons.firstWhere((a) => a['id'] == id, orElse: () => null);
      if (addon != null) {
        total += double.tryParse(addon['price'].toString()) ?? 0;
      }
    }
    _finalPriceController.text = total.toStringAsFixed(0);
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  Future<void> _goToStep(int step) async {
    if (step == 1) {
      if (!_step1Key.currentState!.validate()) return;
      if (_scheduledAt == null) {
        _snack('Tentukan jadwal layanan terlebih dahulu.');
        return;
      }
      // Auto-fill nama PJ dari PIC jika belum diisi
      if (_pjNameController.text.trim().isEmpty && _picNameController.text.trim().isNotEmpty) {
        _pjNameController.text = _picNameController.text.trim();
      }
    }
    if (step == 2) {
      if (!_step2Key.currentState!.validate()) return;
      final pjEmpty = _sigPJKey.currentState?.isEmpty ?? true;
      final officerEmpty = _sigOfficerKey.currentState?.isEmpty ?? true;
      if (pjEmpty || officerEmpty) {
        _snack('Tanda tangan PJ dan Officer wajib diisi.');
        return;
      }
    }
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<String?> _padToBase64(GlobalKey<_SignaturePadState> key) async {
    final state = key.currentState;
    if (state == null || state.isEmpty) return null;
    final image = await state.toImage();
    if (image == null) return null;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final pjBase64 = await _padToBase64(_sigPJKey);
      final officerBase64 = await _padToBase64(_sigOfficerKey);

      if (pjBase64 == null || officerBase64 == null) {
        _snack('Tanda tangan tidak valid. Kembali ke langkah 2 dan isi kembali.');
        return;
      }

      final payload = <String, dynamic>{
        // PIC
        'pic_name': _picNameController.text.trim(),
        'pic_phone': _picPhoneController.text.trim(),
        'pic_relation': _picRelation,
        'pic_address': _picAddressController.text.trim(),
        // Almarhum
        'deceased_name': _deceasedNameController.text.trim(),
        'deceased_dob': _deceasedDob != null
            ? DateFormat('yyyy-MM-dd').format(_deceasedDob!)
            : null,
        'deceased_dod': DateFormat('yyyy-MM-dd').format(_deceasedDod),
        'religion': _religion,
        'duka_address': _dukaAddressController.text.trim(),
        'pickup_address': _pickupAddressController.text.trim(),
        'destination_address': _destinationAddressController.text.trim(),
        'package_id': _selectedPackageId,
        'addon_ids': _selectedAddonIds,
        'so_notes': _soNotesController.text.trim().isEmpty
            ? null
            : _soNotesController.text.trim(),
        'estimated_guests': int.tryParse(_estimatedGuestsController.text.trim()),
        'scheduled_at': _scheduledAt!.toIso8601String(),
        'estimated_duration_hours':
            double.tryParse(_durationController.text.trim()) ?? 3,
        'final_price':
            double.tryParse(_finalPriceController.text.trim()) ?? 0,
        'payment_method': _paymentMethod,
        'pj_name': _pjNameController.text.trim(),
        'pj_signature': pjBase64,
        'officer_name': _officerNameController.text.trim(),
        'officer_signature': officerBase64,
      };

      final res = await widget.repo.createOrder(payload);

      if (!mounted) return;

      if (res.data['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.statusSuccess),
                SizedBox(width: 10),
                Text('Order Dibuat!'),
              ],
            ),
            content: const Text(
              'Order berhasil dibuat dan telah dikonfirmasi. Semua tim akan mendapat notifikasi.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception(res.data['message'] ?? 'Gagal membuat order');
      }
    } catch (e) {
      if (mounted) _snack('Gagal membuat order: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Input Order Baru',
        accentColor: _roleColor,
        showBack: true,
        leading: BackButton(onPressed: _goBack),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    const steps = ['Data Order', 'Form SAL', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _roleColor
                              : AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? _roleColor : AppColors.textHint,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Data Almarhum & Layanan
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PIC (sama seperti consumer form) ────────────────────────────
            _sectionLabel('Data Penanggung Jawab (PIC)'),
            _formField(
              controller: _picNameController,
              label: 'Nama Lengkap PIC *',
              icon: Icons.person_outline,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _picPhoneController,
              label: 'Nomor HP PIC *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _dropdownField<String>(
              label: 'Hubungan dengan Almarhum *',
              icon: Icons.people_outline,
              value: _picRelation,
              items: const [
                DropdownMenuItem(value: 'anak', child: Text('Anak')),
                DropdownMenuItem(value: 'suami_istri', child: Text('Suami / Istri')),
                DropdownMenuItem(value: 'orang_tua', child: Text('Orang Tua')),
                DropdownMenuItem(value: 'saudara', child: Text('Saudara')),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (v) => setState(() => _picRelation = v!),
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _picAddressController,
              label: 'Alamat PIC *',
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),

            const SizedBox(height: 24),

            // ── Almarhum ────────────────────────────────────────────────────
            _sectionLabel('Data Almarhum / Almarhumah'),
            _formField(
              controller: _deceasedNameController,
              label: 'Nama Almarhum *',
              icon: Icons.person_off_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _dateTile(
              label: 'Tanggal Lahir (opsional)',
              icon: Icons.cake_outlined,
              value: _deceasedDob,
              onPick: (d) => setState(() => _deceasedDob = d),
              allowFuture: false,
              required: false,
            ),
            const SizedBox(height: 12),
            _dateTile(
              label: 'Tanggal Meninggal *',
              icon: Icons.calendar_today_outlined,
              value: _deceasedDod,
              onPick: (d) => setState(() => _deceasedDod = d),
              allowFuture: false,
              required: true,
            ),
            const SizedBox(height: 12),
            _dropdownField<String>(
              label: 'Agama *',
              icon: Icons.auto_stories_outlined,
              value: _religion,
              items: const [
                DropdownMenuItem(value: 'islam', child: Text('Islam')),
                DropdownMenuItem(value: 'kristen', child: Text('Kristen')),
                DropdownMenuItem(value: 'katolik', child: Text('Katolik')),
                DropdownMenuItem(value: 'hindu', child: Text('Hindu')),
                DropdownMenuItem(value: 'buddha', child: Text('Buddha')),
                DropdownMenuItem(value: 'konghucu', child: Text('Konghucu')),
              ],
              onChanged: (v) => setState(() => _religion = v!),
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _dukaAddressController,
              label: 'Alamat Duka *',
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _pickupAddressController,
              label: 'Alamat Penjemputan *',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _destinationAddressController,
              label: 'Alamat Tujuan / Pemakaman *',
              icon: Icons.flag_outlined,
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),

            const SizedBox(height: 24),

            // ── Paket ────────────────────────────────────────────────────────
            _sectionLabel('Paket Layanan'),
            _isLoadingPackages
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedPackageId,
                    validator: (v) => v == null ? 'Pilih paket utama' : null,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Paket Utama *',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppColors.textHint, size: 20),
                    ),
                    items: _packages.map((pkg) {
                      final price = _currency.format(
                          double.tryParse(pkg['base_price'].toString()) ?? 0);
                      return DropdownMenuItem<String>(
                        value: pkg['id'],
                        child: Text(
                          '${pkg['name']} — $price',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPackageId = val;
                        _selectedPackage = val == null
                            ? null
                            : _packages.cast<Map<String, dynamic>?>().firstWhere(
                                (p) => p?['id'] == val,
                                orElse: () => null,
                              );
                      });
                      _recalcPrice();
                    },
                  ),

            if (_addons.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Layanan Tambahan (opsional)',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ..._addons.map((addon) {
                final selected = _selectedAddonIds.contains(addon['id']);
                final price = _currency
                    .format(double.tryParse(addon['price'].toString()) ?? 0);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${addon['name']} — $price',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                  value: selected,
                  activeColor: _roleColor,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedAddonIds.add(addon['id']);
                      } else {
                        _selectedAddonIds.remove(addon['id']);
                      }
                    });
                    _recalcPrice();
                  },
                );
              }),
            ],

            const SizedBox(height: 24),

            // ── Jadwal & Detail ───────────────────────────────────────────────
            _sectionLabel('Jadwal & Detail Layanan'),
            _dateTimeTile(),
            const SizedBox(height: 12),
            _formField(
              controller: _durationController,
              label: 'Estimasi Durasi (jam) *',
              icon: Icons.timer_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d < 0.5) return 'Minimal 0.5 jam';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _estimatedGuestsController,
              label: 'Estimasi Tamu',
              icon: Icons.people_outline,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _soNotesController,
              label: 'Catatan SO (opsional)',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // ── Harga & Pembayaran ────────────────────────────────────────────
            _sectionLabel('Harga & Pembayaran'),
            _formField(
              controller: _finalPriceController,
              label: 'Harga Akhir (Rp) *',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (double.tryParse(v.trim()) == null) return 'Angka tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _paymentToggle(),

            const SizedBox(height: 32),
            _nextButton(
              label: 'Lanjut ke Form SAL',
              onTap: () => _goToStep(1),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 2 — Form Persetujuan Layanan (SAL)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    final pkgName = _selectedPackage?['name'] as String? ?? '-';
    final priceText = _finalPriceController.text.isNotEmpty
        ? _currency
            .format(double.tryParse(_finalPriceController.text) ?? 0)
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ringkasan Order ──────────────────────────────────────────────
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Persetujuan Layanan',
                    style: TextStyle(
                      color: _roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Divider(height: 16),
                  _summaryRow('Almarhum',
                      _deceasedNameController.text.trim().isEmpty
                          ? '-'
                          : _deceasedNameController.text.trim()),
                  _summaryRow('Paket', pkgName),
                  _summaryRow('Total Harga', priceText),
                  _summaryRow('Metode Bayar',
                      _paymentMethod == 'cash' ? 'Cash' : 'Transfer'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionLabel('Data Penanggung Jawab Keluarga'),

            _formField(
              controller: _pjNameController,
              label: 'Nama PJ Keluarga *',
              icon: Icons.person_outline,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            _signatureBlock(
              label: 'Tanda Tangan PJ Keluarga *',
              padKey: _sigPJKey,
            ),

            const SizedBox(height: 20),
            _sectionLabel('Data Officer'),

            _formField(
              controller: _officerNameController,
              label: 'Nama Officer *',
              icon: Icons.badge_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            _signatureBlock(
              label: 'Tanda Tangan Officer *',
              padKey: _sigOfficerKey,
            ),

            const SizedBox(height: 16),
            GlassWidget(
              borderRadius: 12,
              blurSigma: 12,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(14),
              child: const Text(
                'Dengan menandatangani form ini, pihak keluarga menyetujui '
                'layanan pemakaman Santa Maria sesuai paket yang dipilih.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),
            _nextButton(
              label: 'Lanjut ke Review',
              onTap: () => _goToStep(2),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 3 — Review & Submit
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildStep3() {
    final priceText = _finalPriceController.text.isNotEmpty
        ? _currency
            .format(double.tryParse(_finalPriceController.text) ?? 0)
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ringkasan Order'),
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('Nama PIC', _picNameController.text.trim()),
                _summaryRow('HP PIC', _picPhoneController.text.trim()),
                _summaryRow('Hubungan', _picRelation),
                const Divider(height: 16),
                _summaryRow(
                  'Almarhum',
                  _deceasedNameController.text.trim().isEmpty
                      ? '-'
                      : _deceasedNameController.text.trim(),
                ),
                _summaryRow('Agama', _religion),
                _summaryRow('Alamat Duka',
                    _dukaAddressController.text.trim().isEmpty
                        ? '-'
                        : _dukaAddressController.text.trim()),
                _summaryRow(
                    'Paket', _selectedPackage?['name'] as String? ?? '-'),
                _summaryRow('Harga Akhir', priceText),
                _summaryRow(
                    'Metode Bayar',
                    _paymentMethod == 'cash' ? 'Cash' : 'Transfer'),
                _summaryRow(
                  'Jadwal',
                  _scheduledAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                          .format(_scheduledAt!)
                      : '-',
                ),
                _summaryRow(
                    'Durasi',
                    _durationController.text.isNotEmpty
                        ? '${_durationController.text} jam'
                        : '-'),
                if (_selectedAddonIds.isNotEmpty)
                  _summaryRow(
                    'Add-on',
                    _addons
                        .where((a) => _selectedAddonIds.contains(a['id']))
                        .map((a) => a['name'].toString())
                        .join(', '),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Penandatangan'),
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('Nama PJ', _pjNameController.text.trim()),
                _summaryRow('Nama Officer',
                    _officerNameController.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline,
                      color: Colors.white),
              label: Text(
                _isSubmitting ? 'Membuat Order...' : 'BUAT ORDER',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _roleColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        ),
        validator: validator,
      );

  Widget _dropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        ),
        items: items,
        onChanged: onChanged,
      );

  Widget _dateTile({
    required String label,
    required IconData icon,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
    required bool allowFuture,
    required bool required,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: allowFuture
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
                Text(
                  value != null
                      ? DateFormat('dd MMMM yyyy').format(value)
                      : (required ? 'Ketuk untuk pilih' : 'Opsional'),
                  style: TextStyle(
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeTile() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _scheduledAt ??
              DateTime.now().add(const Duration(hours: 2)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            _scheduledAt ??
                DateTime.now().add(const Duration(hours: 2)),
          ),
        );
        if (time == null || !mounted) return;
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _scheduledAt != null
                ? _roleColor.withValues(alpha: 0.6)
                : AppColors.textHint.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: _scheduledAt != null ? _roleColor : AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jadwal Layanan *',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  Text(
                    _scheduledAt != null
                        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(_scheduledAt!)
                        : 'Ketuk untuk pilih tanggal & waktu',
                    style: TextStyle(
                      color: _scheduledAt != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _paymentToggle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metode Pembayaran *',
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _payBtn(
                    value: 'cash',
                    label: 'Cash',
                    icon: Icons.money_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _payBtn(
                    value: 'transfer',
                    label: 'Transfer',
                    icon: Icons.account_balance_outlined),
              ),
            ],
          ),
        ],
      );

  Widget _payBtn(
      {required String value,
      required String label,
      required IconData icon}) {
    final active = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              active ? _roleColor.withValues(alpha: 0.12) : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? _roleColor
                : AppColors.glassBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: active ? _roleColor : AppColors.textHint),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? _roleColor : AppColors.textSecondary,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureBlock({
    required String label,
    required GlobalKey<_SignaturePadState> padKey,
  }) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _roleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => padKey.currentState?.clear(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bersihkan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SignaturePad(key: padKey),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tanda tangan di area putih di atas',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _nextButton({required String label, required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _roleColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SignaturePad widget
// ══════════════════════════════════════════════════════════════════════════════

class _SignaturePad extends StatefulWidget {
  const _SignaturePad({super.key});

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  bool get isEmpty => _strokes.isEmpty && _currentStroke == null;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<ui.Image?> toImage() async {
    if (isEmpty) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    final picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) =>
          setState(() => _currentStroke = [d.localPosition]),
      onPanUpdate: (d) =>
          setState(() => _currentStroke?.add(d.localPosition)),
      onPanEnd: (_) {
        if (_currentStroke != null && _currentStroke!.isNotEmpty) {
          setState(() {
            _strokes.add(List.of(_currentStroke!));
            _currentStroke = null;
          });
        }
      },
      child: CustomPaint(
        painter: _SignaturePainter(
          strokes: _strokes,
          currentStroke: _currentStroke,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  _SignaturePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (currentStroke != null) _drawStroke(canvas, currentStroke!, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
