import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SOCreateOrderScreen extends StatefulWidget {
  final SORepository repo;
  const SOCreateOrderScreen({super.key, required this.repo});

  @override
  State<SOCreateOrderScreen> createState() => _SOCreateOrderScreenState();
}

class _SOCreateOrderScreenState extends State<SOCreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _picNameController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _picAddressController = TextEditingController();
  String _picRelation = 'anak';

  final _deceasedNameController = TextEditingController();
  DateTime _deceasedDod = DateTime.now();
  String _deceasedReligion = 'kristen';

  final _pickupAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();

  String? _selectedPackageId;
  List<dynamic> _packages = [];
  bool _isLoadingPackages = true;
  bool _isSubmitting = false;

  static const _roleColor = AppColors.roleSO;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final res = await widget.repo.getPackages();
      if (res.data['success'] == true) {
        if (mounted) setState(() => _packages = res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPackages = false);
  }

  @override
  void dispose() {
    _picNameController.dispose();
    _picPhoneController.dispose();
    _picAddressController.dispose();
    _deceasedNameController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final data = {
        'package_id': _selectedPackageId, // Added package_id
        'pic_name': _picNameController.text,
        'pic_phone': _picPhoneController.text,
        'pic_relation': _picRelation,
        'pic_address': _picAddressController.text,
        'deceased_name': _deceasedNameController.text,
        'deceased_dod': DateFormat('yyyy-MM-dd').format(_deceasedDod),
        'deceased_religion': _deceasedReligion,
        'pickup_address': _pickupAddressController.text,
        'destination_address': _destinationAddressController.text,
      };

      final res = await widget.repo.createOrder(data);

      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order berhasil dibuat!')));
        Navigator.pop(context, true);
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuat order: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Input Order Baru',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Data Penanggung Jawab'),
              const SizedBox(height: 12),
              _field(controller: _picNameController, label: 'Nama PIC', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 14),
              _field(controller: _picPhoneController, label: 'Nomor HP', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 14),
              _dropdown<String>(
                label: 'Hubungan Keluarga',
                icon: Icons.people_outline,
                initialValue: _picRelation,
                items: const [
                  DropdownMenuItem(value: 'anak', child: Text('Anak')),
                  DropdownMenuItem(value: 'suami_istri', child: Text('Suami / Istri')),
                  DropdownMenuItem(value: 'orang_tua', child: Text('Orang Tua')),
                  DropdownMenuItem(value: 'saudara', child: Text('Saudara')),
                  DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                ],
                onChanged: (v) => setState(() => _picRelation = v!),
              ),
              const SizedBox(height: 14),
              _field(controller: _picAddressController, label: 'Alamat PIC', icon: Icons.home_outlined, maxLines: 2, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),

              const SizedBox(height: 28),
              _sectionTitle('Data Almarhum / Almarhumah'),
              const SizedBox(height: 12),
              _field(controller: _deceasedNameController, label: 'Nama Almarhum', icon: Icons.attribution_outlined, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 14),
              _datePicker(),
              const SizedBox(height: 14),
              _dropdown<String>(
                label: 'Agama',
                icon: Icons.auto_stories_outlined,
                initialValue: _deceasedReligion,
                items: const [
                  DropdownMenuItem(value: 'islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'kristen', child: Text('Kristen')),
                  DropdownMenuItem(value: 'katolik', child: Text('Katolik')),
                  DropdownMenuItem(value: 'hindu', child: Text('Hindu')),
                  DropdownMenuItem(value: 'buddha', child: Text('Buddha')),
                  DropdownMenuItem(value: 'konghucu', child: Text('Konghucu')),
                ],
                onChanged: (v) => setState(() => _deceasedReligion = v!),
              ),

              const SizedBox(height: 28),
              _sectionTitle('Lokasi & Logistik'),
              const SizedBox(height: 12),
              _field(controller: _pickupAddressController, label: 'Lokasi Jemput', icon: Icons.location_on_outlined, maxLines: 2, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 14),
              _field(controller: _destinationAddressController, label: 'Lokasi Tujuan (Rumah Duka / Makam)', icon: Icons.church_outlined, maxLines: 2, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),

              const SizedBox(height: 28),
              _sectionTitle('Paket Layanan'),
              const SizedBox(height: 12),
              _isLoadingPackages
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      isExpanded: true, // Prevent right overflow
                      initialValue: _selectedPackageId,
                      validator: (val) => val == null ? 'Pilih paket utama' : null,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Paket Utama',
                        prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 20),
                      ),
                      items: _packages.map((pkg) {
                        final priceText = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                            .format(double.tryParse(pkg['base_price'].toString()) ?? 0);
                        return DropdownMenuItem<String>(
                          value: pkg['id'],
                          child: Text(
                            '${pkg['name']} — $priceText',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPackageId = val),
                    ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('SIMPAN ORDER',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: _roleColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5),
        ),
      );

  Widget _field({
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

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T initialValue,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: initialValue,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        ),
        items: items,
        onChanged: onChanged,
      );

  Widget _datePicker() => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _deceasedDod,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tanggal Meninggal',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_deceasedDod),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
