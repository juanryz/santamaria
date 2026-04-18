import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.39 — Transport Luar Kota: Rp 25.000/KM fix (dari system_threshold).
/// SO set flag + titik penjemputan + jarak → backend auto-calc fee.
class OutOfCityTransportScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  const OutOfCityTransportScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<OutOfCityTransportScreen> createState() =>
      _OutOfCityTransportScreenState();
}

class _OutOfCityTransportScreenState extends State<OutOfCityTransportScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _isOutOfCity = false;
  final _originCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  num _ratePerKm = 25000;
  num _currentFee = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await _api.dio.get('/so/orders/${widget.orderId}/out-of-city');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _isOutOfCity = d['is_out_of_city'] == true;
          _originCtrl.text = (d['origin'] ?? '').toString();
          _distanceCtrl.text = d['distance_km']?.toString() ?? '';
          _currentFee = num.tryParse('${d['transport_fee']}') ?? 0;
          _ratePerKm = num.tryParse('${d['rate_per_km']}') ?? 25000;
        });
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat konfigurasi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _previewFee {
    final d = num.tryParse(_distanceCtrl.text) ?? 0;
    return d * _ratePerKm;
  }

  Future<void> _save() async {
    if (_isOutOfCity && !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final body = {
        'is_out_of_city': _isOutOfCity,
        if (_isOutOfCity) 'origin': _originCtrl.text.trim(),
        if (_isOutOfCity)
          'distance_km': num.tryParse(_distanceCtrl.text) ?? 0,
      };
      final res = await _api.dio
          .put('/so/orders/${widget.orderId}/out-of-city', data: body);
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Tersimpan'),
              backgroundColor: AppColors.statusSuccess),
        );
        final d = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _currentFee = num.tryParse('${d['transport_fee']}') ?? 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal menyimpan'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menyimpan konfigurasi'),
            backgroundColor: AppColors.statusDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Transport Luar Kota — ${widget.orderNumber}',
        accentColor: AppColors.roleSO,
        showBack: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildRateInfo(),
                      const SizedBox(height: 16),
                      GlassWidget(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Order Luar Kota',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          subtitle: const Text(
                              'Aktifkan jika jenazah dari luar kota Semarang',
                              style: TextStyle(fontSize: 12)),
                          value: _isOutOfCity,
                          onChanged: (v) => setState(() => _isOutOfCity = v),
                        ),
                      ),
                      if (_isOutOfCity) ...[
                        const SizedBox(height: 16),
                        _label('Titik Penjemputan'),
                        TextFormField(
                          controller: _originCtrl,
                          decoration: _dec(
                            icon: Icons.place,
                            hint:
                                'cth: Bandara A. Yani, Terminal Banyumanik, Kota Jepara',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Masukkan titik penjemputan'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _label('Jarak (KM)'),
                        TextFormField(
                          controller: _distanceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration:
                              _dec(icon: Icons.straighten, suffix: 'KM'),
                          validator: (v) {
                            final n = num.tryParse(v ?? '');
                            if (n == null || n <= 0) {
                              return 'Masukkan jarak > 0';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        _buildFeePreview(),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label:
                            Text(_saving ? 'Menyimpan…' : 'Simpan Konfigurasi'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRateInfo() => GlassWidget(
        padding: const EdgeInsets.all(14),
        tint: AppColors.statusInfo.withOpacity(0.1),
        borderColor: AppColors.statusInfo.withOpacity(0.3),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.statusInfo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tarif Transport Luar Kota',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('${_rp(_ratePerKm)} / KM (tarif fix)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFeePreview() {
    final preview = _previewFee;
    final savedFee = _currentFee;
    final different = preview != savedFee;

    return GlassWidget(
      padding: const EdgeInsets.all(14),
      tint: AppColors.brandPrimary.withOpacity(0.08),
      borderColor: AppColors.brandPrimary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya Transport',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(_rp(preview),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary)),
            ],
          ),
          if (different && savedFee > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber,
                    size: 14, color: AppColors.statusWarning),
                const SizedBox(width: 4),
                Text('Biaya tersimpan saat ini: ${_rp(savedFee)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.statusWarning)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.statusDanger),
          const SizedBox(height: 12),
          Center(
              child: Text(_error ?? '',
                  style: const TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          Center(
              child: TextButton(
                  onPressed: _load, child: const Text('Coba Lagi'))),
        ],
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(s,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  InputDecoration _dec({IconData? icon, String? hint, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  String _rp(num v) => NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(v);
}
