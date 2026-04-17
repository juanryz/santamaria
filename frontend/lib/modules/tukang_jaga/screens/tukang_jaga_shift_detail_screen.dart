import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/geo_photo_service.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class TukangJagaShiftDetailScreen extends StatefulWidget {
  final String shiftId;
  const TukangJagaShiftDetailScreen({super.key, required this.shiftId});

  @override
  State<TukangJagaShiftDetailScreen> createState() =>
      _TukangJagaShiftDetailScreenState();
}

class _TukangJagaShiftDetailScreenState
    extends State<TukangJagaShiftDetailScreen> {
  final _api = ApiClient();

  bool _isLoading = true;
  bool _isLoadingDeliveries = true;
  bool _isActing = false;
  String? _error;

  Map<String, dynamic>? _shift;
  List<dynamic> _deliveries = [];

  static const _roleColor = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/tukang-jaga/shifts/${widget.shiftId}');
      if (res.data['success'] == true) {
        setState(() => _shift = res.data['data'] as Map<String, dynamic>?);
        _loadDeliveries();
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat shift.');
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat shift. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeliveries() async {
    final orderId = _shift?['order_id']?.toString();
    if (orderId == null) return;
    setState(() => _isLoadingDeliveries = true);
    try {
      final res = await _api.dio
          .get('/tukang-jaga/orders/$orderId/deliveries');
      if (res.data['success'] == true) {
        final all = List<dynamic>.from(res.data['data'] ?? []);
        setState(() =>
            _deliveries = all.where((d) => d['status'] == 'delivered').toList());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingDeliveries = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isActing = true);
    try {
      // Capture selfie photo before check-in
      final geoPhoto = await GeoPhotoService.instance.captureSelfie();
      if (geoPhoto == null) {
        if (mounted) _snack('Foto selfie wajib untuk check-in');
        return;
      }

      // Upload evidence
      await GeoPhotoService.instance.uploadEvidence(
        geoPhoto: geoPhoto,
        context: 'tukang_jaga_checkin',
        referenceType: 'tukang_jaga_shift',
        referenceId: widget.shiftId,
        orderId: _shift?['order_id']?.toString(),
      );

      final formData = FormData.fromMap({
        'selfie_photo': await geoPhoto.toMultipart(fieldName: 'selfie_photo'),
        ...geoPhoto.toMetadata(),
      });

      final res = await _api.dio.post(
        '/tukang-jaga/shifts/${widget.shiftId}/checkin',
        data: formData,
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        _snack('Check-in berhasil!');
        _loadShift();
      } else {
        _snack(res.data['message'] ?? 'Gagal check-in.');
      }
    } catch (e) {
      if (mounted) _snack('Gagal check-in. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isActing = true);
    try {
      // Capture selfie photo before checkout / shift switch
      final geoPhoto = await GeoPhotoService.instance.captureSelfie();
      if (geoPhoto == null) {
        if (mounted) _snack('Foto selfie wajib untuk checkout');
        return;
      }

      // Upload evidence
      await GeoPhotoService.instance.uploadEvidence(
        geoPhoto: geoPhoto,
        context: 'tukang_jaga_shift_switch',
        referenceType: 'tukang_jaga_shift',
        referenceId: widget.shiftId,
        orderId: _shift?['order_id']?.toString(),
      );

      final formData = FormData.fromMap({
        'selfie_photo': await geoPhoto.toMultipart(fieldName: 'selfie_photo'),
        ...geoPhoto.toMetadata(),
      });

      final res = await _api.dio.post(
        '/tukang-jaga/shifts/${widget.shiftId}/checkout',
        data: formData,
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>?;
        _loadShift();
        _showWageDialog(data);
      } else {
        _snack(res.data['message'] ?? 'Gagal checkout.');
      }
    } catch (e) {
      if (mounted) _snack('Gagal checkout. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _showWageDialog(Map<String, dynamic>? data) {
    final wage = data?['wage_amount'] ?? data?['wage'] ?? 0;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checkout Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            const Text('Shift telah selesai.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Upah: ${fmt.format(num.tryParse(wage.toString()) ?? 0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReceive(String deliveryId) async {
    try {
      final res = await _api.dio
          .post('/tukang-jaga/deliveries/$deliveryId/receive');
      if (!mounted) return;
      if (res.data['success'] == true) {
        _snack('Barang dikonfirmasi diterima.');
        _loadDeliveries();
      } else {
        _snack(res.data['message'] ?? 'Gagal konfirmasi.');
      }
    } catch (_) {
      if (mounted) _snack('Gagal konfirmasi. Periksa koneksi Anda.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  Color _shiftTypeColor(String? type) => switch (type) {
        'pagi' => Colors.orange,
        'siang' => Colors.blue,
        'malam' => Colors.purple,
        'full_day' => Colors.teal,
        _ => AppColors.brandSecondary,
      };

  Color _statusColor(String? status) => switch (status) {
        'scheduled' => Colors.grey,
        'active' => Colors.green.shade600,
        'completed' => Colors.blue,
        'missed' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String _statusLabel(String? status) => switch (status) {
        'scheduled' => 'Terjadwal',
        'active' => 'Aktif',
        'completed' => 'Selesai',
        'missed' => 'Terlewat',
        _ => status ?? '-',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Shift',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadShift,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShiftInfo(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildDeliveriesSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.statusDanger, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadShift,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );

  Widget _buildShiftInfo() {
    if (_shift == null) return const SizedBox();
    final status = _shift!['status'] as String?;
    final shiftType = _shift!['shift_type'] as String?;
    final sc = _statusColor(status);
    final tc = _shiftTypeColor(shiftType);
    final order = _shift!['order'] as Map<String, dynamic>?;

    return GlassWidget(
      borderRadius: 20,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: tc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(shiftType?.toUpperCase() ?? '-',
                    style: TextStyle(
                        color: tc, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(status),
                    style: TextStyle(
                        color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order?['deceased_name'] ?? _shift!['deceased_name'] ?? '-',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            order?['order_code'] ?? _shift!['order_code'] ?? '-',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const Divider(height: 24, color: AppColors.glassBorder),
          _infoRow('Nomor Shift', 'Shift ${_shift!['shift_number'] ?? '-'}'),
          const SizedBox(height: 6),
          _infoRow('Mulai', _formatDateTime(_shift!['scheduled_start'])),
          const SizedBox(height: 6),
          _infoRow('Selesai', _formatDateTime(_shift!['scheduled_end'])),
          if (_shift!['actual_checkin'] != null) ...[
            const SizedBox(height: 6),
            _infoRow('Check-in', _formatDateTime(_shift!['actual_checkin'])),
          ],
          if (_shift!['actual_checkout'] != null) ...[
            const SizedBox(height: 6),
            _infoRow('Checkout', _formatDateTime(_shift!['actual_checkout'])),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _buildActionButtons() {
    final status = _shift?['status'] as String?;
    final canCheckIn = status == 'scheduled';
    final canCheckOut = status == 'active';

    if (!canCheckIn && !canCheckOut) return const SizedBox();

    return Column(
      children: [
        if (canCheckIn)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActing ? null : _checkIn,
              icon: _isActing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
              label: const Text('CHECK-IN SEKARANG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (canCheckOut)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActing ? null : _checkOut,
              icon: _isActing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.logout),
              label: const Text('CHECKOUT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Barang Masuk',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_isLoadingDeliveries)
          const Center(child: CircularProgressIndicator())
        else if (_deliveries.isEmpty)
          GlassWidget(
            borderRadius: 16,
            blurSigma: 12,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text('Belum ada pengiriman barang.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...(_deliveries.map((d) => _buildDeliveryCard(d))),
      ],
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final items = List<dynamic>.from(delivery['items'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    delivery['delivered_by_name'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
                Text(
                  _formatDateTime(delivery['delivered_at']),
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.textHint)),
                      Text(
                        '${item['item_name'] ?? '-'} x ${item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    _confirmReceive(delivery['id'].toString()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _roleColor,
                  side: BorderSide(color: _roleColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('KONFIRMASI TERIMA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
