import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/funeral_home_picker.dart';
import '../../../shared/widgets/cemetery_picker.dart';
import '../../../shared/widgets/loading_button.dart';

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
  final _pageController = PageController();
  bool _isSubmitting = false;
  int _step = 0;
  // Steps: 0=KTP/KK, 1=PIC, 2=Almarhum, 3=Rumah Duka & Pemakaman,
  //        4=Paket, 5=Add-on, 6=Vendor, 7=Persetujuan, 8=Review

  // Document uploads (KTP + KK)
  final _imagePicker = ImagePicker();
  File? _ktpPhoto;
  File? _kkPhoto;

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
  final _notesCtrl = TextEditingController();

  // Funeral home & cemetery
  String? _selectedFuneralHomeId;
  String? _selectedFuneralHomeName;
  String? _selectedCemeteryId;
  String? _selectedCemeteryName;

  // Package & add-ons
  String? _selectedPackageId;
  Map<String, dynamic>? _selectedPackage;
  final List<String> _selectedAddonIds = [];
  List<dynamic> _packages = [];
  List<dynamic> _addons = [];
  bool _isLoadingPackages = true;

  // Vendor preferences
  // Key = vendor_role_code, value = 'internal' | 'external' | 'not_needed'
  final Map<String, String> _vendorPrefs = {};
  final Map<String, TextEditingController> _vendorExtNameCtrls = {};
  final Map<String, TextEditingController> _vendorExtPhoneCtrls = {};
  List<dynamic> _vendorRoles = [];

  // SAL fields
  final _pjNameCtrl = TextEditingController();
  final _sigKey = GlobalKey<_SignaturePadState>();
  final _soCodeCtrl = TextEditingController();

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const _roleColor = AppColors.roleConsumer;

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

  static const _totalSteps = 9;

  @override
  void initState() {
    super.initState();
    _applyPrefill();
    _loadData();
  }

  void _applyPrefill() {
    final p = widget.prefill;
    if (p == null) return;
    _picNameCtrl.text = p['pic_name'] ?? '';
    _picPhoneCtrl.text = p['pic_phone'] ?? '';
    _picAddressCtrl.text = p['pic_address'] ?? '';
    _deceasedNameCtrl.text = p['deceased_name'] ?? '';
    _pickupAddressCtrl.text = p['pickup_address'] ?? '';
    if (p['pic_relation'] != null) _picRelation = p['pic_relation'];
    if (p['deceased_religion'] != null) {
      _deceasedReligion = p['deceased_religion'];
    }
    if (p['deceased_dod'] != null) {
      _deceasedDod = DateTime.tryParse(p['deceased_dod']);
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.dio.get('/packages', queryParameters: {'check_stock': 'true'}),
        _api.dio.get('/addons'),
        _api.dio.get('/v1/public/vendor-roles').catchError((_) =>
            Response(requestOptions: RequestOptions(), data: {'success': false})),
      ]);
      if (!mounted) return;
      if (results[0].data['success'] == true) {
        setState(() => _packages = results[0].data['data'] as List);
      }
      if (results[1].data['success'] == true) {
        setState(() => _addons = results[1].data['data'] as List);
      }
      if (results[2].data['success'] == true) {
        setState(() => _vendorRoles = results[2].data['data'] as List);
        for (final role in _vendorRoles) {
          final code = role['role_code'] as String;
          _vendorPrefs[code] = 'internal';
          _vendorExtNameCtrls[code] = TextEditingController();
          _vendorExtPhoneCtrls[code] = TextEditingController();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPackages = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _picNameCtrl.dispose();
    _picPhoneCtrl.dispose();
    _picAddressCtrl.dispose();
    _deceasedNameCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _notesCtrl.dispose();
    _pjNameCtrl.dispose();
    _soCodeCtrl.dispose();
    for (final c in _vendorExtNameCtrls.values) {
      c.dispose();
    }
    for (final c in _vendorExtPhoneCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _padToBase64(GlobalKey<_SignaturePadState> key) async {
    final state = key.currentState;
    if (state == null || state.isEmpty) return null;
    final image = await state.toImage();
    if (image == null) return null;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  // ── Validation per step ─────────────────────────────────────────────────

  bool _validateCurrentStep() {
    switch (_step) {
      case 0: // KTP/KK
        if (_ktpPhoto == null) { _snack('Foto KTP wajib diunggah.'); return false; }
        if (_kkPhoto == null) { _snack('Foto Kartu Keluarga wajib diunggah.'); return false; }
        return true;
      case 1: // PIC
        if (_picNameCtrl.text.trim().isEmpty) { _snack('Masukkan nama PIC.'); return false; }
        if (_picPhoneCtrl.text.trim().isEmpty) { _snack('Masukkan nomor HP PIC.'); return false; }
        if (_picAddressCtrl.text.trim().isEmpty) { _snack('Masukkan alamat PIC.'); return false; }
        return true;
      case 2: // Almarhum
        if (_deceasedNameCtrl.text.trim().isEmpty) { _snack('Masukkan nama almarhum.'); return false; }
        if (_deceasedDod == null) { _snack('Pilih tanggal meninggal.'); return false; }
        if (_pickupAddressCtrl.text.trim().isEmpty) { _snack('Masukkan alamat penjemputan.'); return false; }
        return true;
      case 3: // Funeral home
        if (_selectedFuneralHomeId == null) { _snack('Pilih rumah duka.'); return false; }
        return true;
      case 4: // Package
        if (_selectedPackageId == null) { _snack('Pilih paket layanan.'); return false; }
        return true;
      case 5: // Add-ons (optional, always valid)
        return true;
      case 6: // Vendor (optional, always valid)
        return true;
      case 7: // SAL
        if (_pjNameCtrl.text.trim().isEmpty) { _snack('Masukkan nama penandatangan.'); return false; }
        if (_sigKey.currentState?.isEmpty ?? true) { _snack('Tanda tangan wajib diisi.'); return false; }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    // Auto-fill pjName from picName when entering SAL step
    if (_step == 6 && _pjNameCtrl.text.trim().isEmpty && _picNameCtrl.text.trim().isNotEmpty) {
      _pjNameCtrl.text = _picNameCtrl.text.trim();
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final pjBase64 = await _padToBase64(_sigKey);
    if (pjBase64 == null) {
      _snack('Tanda tangan tidak valid. Kembali dan isi ulang.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Build vendor preferences
      final vendorRequests = <Map<String, dynamic>>[];
      for (final entry in _vendorPrefs.entries) {
        final pref = entry.value;
        final req = <String, dynamic>{
          'vendor_role_code': entry.key,
          'preference': pref,
        };
        if (pref == 'external') {
          req['ext_name'] = _vendorExtNameCtrls[entry.key]?.text.trim() ?? '';
          req['ext_phone'] = _vendorExtPhoneCtrls[entry.key]?.text.trim() ?? '';
        }
        vendorRequests.add(req);
      }

      final payload = <String, dynamic>{
        'pic_name': _picNameCtrl.text.trim(),
        'pic_phone': _picPhoneCtrl.text.trim(),
        'pic_relation': _picRelation,
        'pic_address': _picAddressCtrl.text.trim(),
        'deceased_name': _deceasedNameCtrl.text.trim(),
        'deceased_dod': DateFormat('yyyy-MM-dd').format(_deceasedDod!),
        'deceased_religion': _deceasedReligion,
        'pickup_address': _pickupAddressCtrl.text.trim(),
        'funeral_home_id': _selectedFuneralHomeId,
        'cemetery_id': _selectedCemeteryId,
        'package_id': _selectedPackageId,
        'addon_ids': _selectedAddonIds,
        'notes': _notesCtrl.text.trim(),
        'pj_name': _pjNameCtrl.text.trim(),
        'pj_signature': pjBase64,
        'vendor_requests': vendorRequests,
        if (_soCodeCtrl.text.trim().isNotEmpty)
          'so_code': _soCodeCtrl.text.trim(),
      };

      final res = await _api.dio.post('/consumer/orders', data: payload);
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order berhasil dibuat. Tim kami akan segera menghubungi Anda.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
        Navigator.pop(context, true);
      } else {
        final msg = res.data['message'] ?? '';
        if (msg == 'INVALID_SO_CODE') {
          _showInvalidSoCodeDialog();
        } else {
          _snack(msg.isNotEmpty ? msg : 'Gagal membuat order.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('INVALID_SO_CODE')) {
        _showInvalidSoCodeDialog();
      } else {
        _snack('Terjadi kesalahan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showInvalidSoCodeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kode SO Tidak Valid'),
        content: const Text('Kode SO tidak valid. Kosongkan jika tidak dipandu oleh SO.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickImage({required bool isKtp}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _imagePicker.pickImage(
      source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      if (isKtp) { _ktpPhoto = File(picked.path); } else { _kkPhoto = File(picked.path); }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Pesan Layanan',
        accentColor: _roleColor,
        showBack: true,
        leading: BackButton(onPressed: _prevStep),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepDocuments(),   // 0
                _buildStepPIC(),         // 1
                _buildStepAlmarhum(),    // 2
                _buildStepLocation(),    // 3
                _buildStepPackage(),     // 4
                _buildStepAddons(),      // 5
                _buildStepVendor(),      // 6
                _buildStepSAL(),         // 7
                _buildStepReview(),      // 8
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    const labels = ['Dok', 'PIC', 'Alm', 'Lokasi', 'Paket', 'Add-on', 'Vendor', 'TTD', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive ? _roleColor : AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(labels[i],
                          style: TextStyle(
                            fontSize: 8,
                            color: isActive ? _roleColor : AppColors.textHint,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
                if (i < labels.length - 1) const SizedBox(width: 3),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 0: KTP/KK Documents ──────────────────────────────────────────────

  Widget _buildStepDocuments() {
    return _stepScaffold(
      title: 'Upload Dokumen',
      subtitle: 'Foto KTP dan Kartu Keluarga penanggung jawab wajib diunggah.',
      children: [
        _documentUploadTile(label: 'Foto KTP Penanggung Jawab', file: _ktpPhoto,
            onTap: () => _pickImage(isKtp: true), onClear: () => setState(() => _ktpPhoto = null)),
        const SizedBox(height: 14),
        _documentUploadTile(label: 'Foto Kartu Keluarga', file: _kkPhoto,
            onTap: () => _pickImage(isKtp: false), onClear: () => setState(() => _kkPhoto = null)),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 1: PIC ───────────────────────────────────────────────────────────

  Widget _buildStepPIC() {
    return _stepScaffold(
      title: 'Data Penanggung Jawab',
      subtitle: 'Orang yang bertanggung jawab atas layanan ini.',
      children: [
        _field(controller: _picNameCtrl, label: 'Nama Lengkap PIC *', icon: Icons.person_outline),
        const SizedBox(height: 14),
        _field(controller: _picPhoneCtrl, label: 'Nomor HP PIC *', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _dropdown<String>(
          label: 'Hubungan dengan Almarhum',
          value: _picRelation,
          items: _relations.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
          onChanged: (v) => setState(() => _picRelation = v!),
        ),
        const SizedBox(height: 14),
        _field(controller: _picAddressCtrl, label: 'Alamat PIC *', icon: Icons.home_outlined, maxLines: 3),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 2: Almarhum ──────────────────────────────────────────────────────

  Widget _buildStepAlmarhum() {
    return _stepScaffold(
      title: 'Data Almarhum / Almarhumah',
      children: [
        _field(controller: _deceasedNameCtrl, label: 'Nama Almarhum *', icon: Icons.person_outline),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context, initialDate: DateTime.now(),
              firstDate: DateTime(2000), lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _deceasedDod = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.textHint.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.textHint, size: 20),
              const SizedBox(width: 12),
              Text(
                _deceasedDod != null ? DateFormat('d MMMM yyyy', 'id').format(_deceasedDod!) : 'Tanggal Meninggal *',
                style: TextStyle(color: _deceasedDod != null ? AppColors.textPrimary : AppColors.textHint, fontSize: 14),
              ),
            ]),
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
        _field(controller: _pickupAddressCtrl, label: 'Alamat Penjemputan *', icon: Icons.location_on_outlined, maxLines: 3),
        const SizedBox(height: 14),
        _field(controller: _notesCtrl, label: 'Catatan Tambahan (opsional)', icon: Icons.notes_outlined, maxLines: 3),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 3: Funeral Home & Cemetery ───────────────────────────────────────

  Widget _buildStepLocation() {
    return _stepScaffold(
      title: 'Rumah Duka & Pemakaman',
      children: [
        const Text('Rumah Duka *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FuneralHomePicker(
          initialId: _selectedFuneralHomeId,
          initialName: _selectedFuneralHomeName,
          onSelected: (id, name) => setState(() {
            _selectedFuneralHomeId = id;
            _selectedFuneralHomeName = name;
          }),
        ),
        if (_selectedFuneralHomeName != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 14),
            const SizedBox(width: 4),
            Text(_selectedFuneralHomeName!, style: const TextStyle(color: AppColors.statusSuccess, fontSize: 12)),
          ]),
        ],
        const SizedBox(height: 24),
        const Text('Pemakaman / Krematorium (opsional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CemeteryPicker(
          initialId: _selectedCemeteryId,
          initialName: _selectedCemeteryName,
          onSelected: (id, name) => setState(() {
            _selectedCemeteryId = id;
            _selectedCemeteryName = name;
          }),
        ),
        if (_selectedCemeteryName != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 14),
            const SizedBox(width: 4),
            Text(_selectedCemeteryName!, style: const TextStyle(color: AppColors.statusSuccess, fontSize: 12)),
          ]),
        ],
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 4: Package Selection ─────────────────────────────────────────────

  Widget _buildStepPackage() {
    if (_isLoadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }
    return _stepScaffold(
      title: 'Pilih Paket Layanan',
      subtitle: 'Pilih paket yang sesuai dengan kebutuhan.',
      children: [
        ..._packages.map((pkg) {
          final id = pkg['id'] as String;
          final name = pkg['name'] as String? ?? '';
          final price = double.tryParse(pkg['base_price']?.toString() ?? '0') ?? 0;
          final stockStatus = pkg['stock_status'] as String? ?? 'available';
          final canSelect = pkg['can_select'] as bool? ?? true;
          final isSelected = _selectedPackageId == id;
          final sc = stockStatus == 'available'
              ? AppColors.statusSuccess
              : stockStatus == 'partial'
                  ? AppColors.statusWarning
                  : AppColors.statusDanger;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassWidget(
              borderRadius: 16, blurSigma: 12,
              tint: isSelected ? _roleColor.withValues(alpha: 0.08) : AppColors.glassWhite,
              borderColor: isSelected ? _roleColor : AppColors.glassBorder,
              padding: const EdgeInsets.all(16),
              onTap: canSelect ? () => setState(() { _selectedPackageId = id; _selectedPackage = pkg; }) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(name, style: TextStyle(
                      color: canSelect ? AppColors.textPrimary : AppColors.textHint,
                      fontWeight: FontWeight.bold, fontSize: 15))),
                    if (isSelected) const Icon(Icons.check_circle, color: _roleColor, size: 20),
                  ]),
                  const SizedBox(height: 4),
                  Text(_currency.format(price), style: TextStyle(
                    color: canSelect ? _roleColor : AppColors.textHint,
                    fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      stockStatus == 'available' ? 'Tersedia'
                          : stockStatus == 'partial' ? 'Sebagian tersedia'
                          : 'Tidak tersedia',
                      style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 5: Add-ons ───────────────────────────────────────────────────────

  Widget _buildStepAddons() {
    return _stepScaffold(
      title: 'Layanan Tambahan',
      subtitle: 'Pilih layanan tambahan jika diperlukan (opsional).',
      children: [
        if (_addons.isEmpty)
          const Center(child: Text('Tidak ada layanan tambahan tersedia.',
              style: TextStyle(color: AppColors.textHint)))
        else
          ..._addons.map((addon) {
            final id = addon['id'] as String;
            final name = addon['name'] ?? '';
            final price = double.tryParse(addon['price']?.toString() ?? '0') ?? 0;
            final selected = _selectedAddonIds.contains(id);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero, dense: true,
              title: Text('$name -- ${_currency.format(price)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              value: selected, activeColor: _roleColor,
              onChanged: (val) => setState(() {
                if (val == true) { _selectedAddonIds.add(id); } else { _selectedAddonIds.remove(id); }
              }),
            );
          }),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 6: Vendor Preferences ────────────────────────────────────────────

  Widget _buildStepVendor() {
    return _stepScaffold(
      title: 'Preferensi Vendor',
      subtitle: 'Pilih apakah menggunakan vendor dari Santa Maria atau Anda punya sendiri.',
      children: [
        if (_vendorRoles.isEmpty)
          const Text('Data vendor belum tersedia.',
              style: TextStyle(color: AppColors.textHint, fontSize: 13))
        else
          ..._vendorRoles.map((role) {
            final code = role['role_code'] as String;
            final name = role['role_name'] as String? ?? code;
            final pref = _vendorPrefs[code] ?? 'internal';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _choiceChip('Dari SM', pref == 'internal', () => setState(() => _vendorPrefs[code] = 'internal')),
                    _choiceChip('Punya Sendiri', pref == 'external', () => setState(() => _vendorPrefs[code] = 'external')),
                    _choiceChip('Tidak Perlu', pref == 'not_needed', () => setState(() => _vendorPrefs[code] = 'not_needed')),
                  ]),
                  if (pref == 'external') ...[
                    const SizedBox(height: 10),
                    _field(controller: _vendorExtNameCtrls[code]!, label: 'Nama Vendor', icon: Icons.person_outline),
                    const SizedBox(height: 8),
                    _field(controller: _vendorExtPhoneCtrls[code]!, label: 'No. WhatsApp', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  ],
                ],
              ),
            );
          }),
      ],
      onNext: _nextStep,
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _roleColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _roleColor : AppColors.textHint.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? _roleColor : AppColors.textSecondary,
          fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  // ── Step 7: SAL (Signature) ───────────────────────────────────────────────

  Widget _buildStepSAL() {
    return _stepScaffold(
      title: 'Form Persetujuan Layanan',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Dengan menandatangani form ini, Anda menyetujui layanan pemakaman Santa Maria.',
                  style: TextStyle(color: Colors.blue, fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _field(controller: _pjNameCtrl, label: 'Nama Penandatangan *', icon: Icons.person_outline),
        const SizedBox(height: 20),
        _signatureBlock(label: 'Tanda Tangan Digital *', padKey: _sigKey),
        const SizedBox(height: 20),
        TextFormField(
          controller: _soCodeCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textHint, size: 20),
            labelText: 'Kode SO (opsional)',
            hintText: 'Masukkan kode SO jika dipandu oleh Service Officer',
          ),
        ),
        const SizedBox(height: 6),
        const Text('Kosongkan jika tidak dipandu oleh SO',
            style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
      onNext: _nextStep,
    );
  }

  // ── Step 8: Review ────────────────────────────────────────────────────────

  Widget _buildStepReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Konfirmasi Data'),
          const SizedBox(height: 4),
          const Text('Pastikan data sudah benar sebelum mengirim.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(height: 20),
          _confirmCard(label: 'DOKUMEN', rows: [
            ('KTP', _ktpPhoto != null ? 'Sudah diunggah' : 'Belum'),
            ('KK', _kkPhoto != null ? 'Sudah diunggah' : 'Belum'),
          ]),
          const SizedBox(height: 14),
          _confirmCard(label: 'PENANGGUNG JAWAB', rows: [
            ('Nama', _picNameCtrl.text),
            ('HP', _picPhoneCtrl.text),
            ('Hubungan', _relations.firstWhere((r) => r.$1 == _picRelation).$2),
            ('Alamat', _picAddressCtrl.text),
          ]),
          const SizedBox(height: 14),
          _confirmCard(label: 'ALMARHUM', rows: [
            ('Nama', _deceasedNameCtrl.text),
            ('Tgl Meninggal', _deceasedDod != null ? DateFormat('d MMMM yyyy', 'id').format(_deceasedDod!) : '-'),
            ('Agama', _religions.firstWhere((r) => r.$1 == _deceasedReligion).$2),
            ('Penjemputan', _pickupAddressCtrl.text),
          ]),
          const SizedBox(height: 14),
          _confirmCard(label: 'LOKASI', rows: [
            ('Rumah Duka', _selectedFuneralHomeName ?? '-'),
            ('Pemakaman', _selectedCemeteryName ?? '-'),
          ]),
          const SizedBox(height: 14),
          _confirmCard(label: 'LAYANAN', rows: [
            ('Paket', _selectedPackage?['name'] ?? '-'),
            if (_selectedAddonIds.isNotEmpty)
              ('Add-on', _addons.where((a) => _selectedAddonIds.contains(a['id'])).map((a) => a['name']).join(', ')),
          ]),
          const SizedBox(height: 14),
          _confirmCard(label: 'PERSETUJUAN', rows: [
            ('Penandatangan', _pjNameCtrl.text),
            ('Tanda Tangan', 'Sudah ditandatangani'),
          ]),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'KIRIM ORDER',
            loadingLabel: 'Mengirim...',
            isLoading: _isSubmitting,
            onPressed: _submit,
            color: AppColors.statusSuccess,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Reusable step scaffold ────────────────────────────────────────────────

  Widget _stepScaffold({
    required String title,
    String? subtitle,
    required List<Widget> children,
    required VoidCallback onNext,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
        Container(
          color: AppColors.backgroundSoft,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: _roleColor, foregroundColor: Colors.white),
              child: const Text('LANJUT'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _documentUploadTile({
    required String label, required File? file,
    required VoidCallback onTap, required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: file == null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: file != null ? AppColors.statusSuccess.withValues(alpha: 0.5) : AppColors.textHint.withValues(alpha: 0.3)),
        ),
        child: file != null
            ? Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 14),
                    SizedBox(width: 4),
                    Text('Foto berhasil diunggah', style: TextStyle(color: AppColors.statusSuccess, fontSize: 11)),
                  ]),
                ])),
                GestureDetector(onTap: onClear, child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                )),
              ])
            : Row(children: [
                Container(width: 60, height: 60,
                  decoration: BoxDecoration(color: _roleColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_a_photo_outlined, color: _roleColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Ketuk untuk ambil foto atau pilih dari galeri', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                ])),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18));

  Widget _confirmCard({required String label, required List<(String, String)> rows}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 110, child: Text(r.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  Expanded(child: Text(r.$2.isNotEmpty ? r.$2 : '-', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                ]),
              )),
        ]),
      );

  Widget _field({
    required TextEditingController controller, required String label, required IconData icon,
    TextInputType keyboardType = TextInputType.text, int maxLines = 1,
  }) => TextFormField(
        controller: controller, keyboardType: keyboardType, maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(prefixIcon: Icon(icon, color: AppColors.textHint, size: 20), labelText: label),
      );

  Widget _dropdown<T>({
    required String label, required T value,
    required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
        initialValue: value,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(labelText: label),
        items: items, onChanged: onChanged,
      );

  Widget _signatureBlock({required String label, required GlobalKey<_SignaturePadState> padKey}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: _roleColor, fontSize: 13, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => padKey.currentState?.clear(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Text('Bersihkan', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, height: 150,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _SignaturePad(key: padKey)),
        ),
        const SizedBox(height: 6),
        const Text('Tanda tangan di area putih di atas', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ]),
    );
  }
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

  void clear() => setState(() { _strokes.clear(); _currentStroke = null; });

  Future<ui.Image?> toImage() async {
    if (isEmpty) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    final paint = Paint()..color = Colors.black..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final stroke in _strokes) { _drawStroke(canvas, stroke, paint); }
    return recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) { canvas.drawPoints(ui.PointMode.points, points, paint); return; }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1]; final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => setState(() => _currentStroke = [d.localPosition]),
      onPanUpdate: (d) => setState(() => _currentStroke?.add(d.localPosition)),
      onPanEnd: (_) {
        if (_currentStroke != null && _currentStroke!.isNotEmpty) {
          setState(() { _strokes.add(List.of(_currentStroke!)); _currentStroke = null; });
        }
      },
      child: CustomPaint(painter: _SignaturePainter(strokes: _strokes, currentStroke: _currentStroke), size: Size.infinite),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  _SignaturePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final stroke in strokes) { _drawStroke(canvas, stroke, paint); }
    if (currentStroke != null) _drawStroke(canvas, currentStroke!, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) { canvas.drawPoints(ui.PointMode.points, points, paint); return; }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1]; final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
