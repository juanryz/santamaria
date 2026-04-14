import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'so_death_cert_screen.dart';
import 'so_extra_approval_screen.dart';
import 'so_acceptance_letter_screen.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../tukang_foto/screens/gallery_link_screen.dart';

class SOOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final SORepository repo;

  const SOOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.repo,
  });

  @override
  State<SOOrderDetailScreen> createState() => _SOOrderDetailScreenState();
}

class _SOOrderDetailScreenState extends State<SOOrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<dynamic> _packages = [];
  List<dynamic> _addonsList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAddingAddon = false;
  String? _error;

  String? _selectedPackageId;
  Map<String, dynamic>?
  _selectedPackage; // holds full pkg object for price display
  final _finalPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _guestsController = TextEditingController();
  final _durationController = TextEditingController(text: '3');
  DateTime? _scheduledAt;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const _roleColor = AppColors.roleSO;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _finalPriceController.dispose();
    _notesController.dispose();
    _guestsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repo.getOrderDetail(widget.orderId),
        widget.repo.getPackages(),
        widget.repo.getAddOns(),
      ]);

      final orderRes = results[0];
      final pkgRes = results[1];
      final addonRes = results[2];

      if (orderRes.data['success'] == true) {
        final order = orderRes.data['data'] as Map<String, dynamic>;
        setState(() {
          _order = order;
          _finalPriceController.text =
              (order['final_price'] ?? order['estimated_price'] ?? '')
                  .toString();
          _guestsController.text = (order['estimated_guests'] ?? '').toString();
        });
      }
      if (pkgRes.data['success'] == true) {
        setState(() => _packages = pkgRes.data['data'] as List);
      }
      if (addonRes.data['success'] == true) {
        setState(() => _addonsList = addonRes.data['data'] as List);
      }
      if (_order?['package_id'] != null) {
        final pid = _order!['package_id'] as String;
        setState(() {
          _selectedPackageId = pid;
          _selectedPackage = _packages.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id'] == pid,
            orElse: () => null,
          );
        });
      }
      _recalculateFinalPrice();
    } catch (e) {
      setState(() => _error = 'Gagal memuat data order.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _recalculateFinalPrice() {
    double total = 0;
    if (_selectedPackage != null) {
      total += double.tryParse(_selectedPackage!['base_price'].toString()) ?? 0;
    }
    final List<dynamic> addons = _order?['order_add_ons'] ?? [];
    for (var addon in addons) {
      final price = double.tryParse(addon['price_at_time'].toString()) ?? 0;
      final qty = int.tryParse(addon['quantity'].toString()) ?? 1;
      total += (price * qty);
    }
    _finalPriceController.text = total.toStringAsFixed(0);
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? DateTime.now().add(const Duration(hours: 2)),
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
  }

  Future<void> _showStockPreview() async {
    if (_selectedPackageId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final api = ApiClient();
      final res = await api.dio.get(
        '/so/orders/${widget.orderId}/stock-check',
        queryParameters: {'package_id': _selectedPackageId},
      );
      if (!mounted) return;
      Navigator.pop(context);
      final resData = res.data['data'] as Map<String, dynamic>? ?? {};
      final data = resData['items'] as List? ?? [];
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Ketersediaan Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (data.isEmpty)
                const Text('Semua stok tersedia.', style: TextStyle(color: AppColors.statusSuccess))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = data[i] as Map<String, dynamic>;
                      final available = (item['available'] ?? 0) as num;
                      final needed = (item['needed'] ?? 0) as num;
                      final ok = available >= needed;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded, color: ok ? AppColors.statusSuccess : AppColors.statusWarning, size: 20),
                        title: Text(item['item_name'] ?? '-', style: const TextStyle(fontSize: 13)),
                        trailing: Text('${available.toInt()} / ${needed.toInt()}', style: TextStyle(color: ok ? AppColors.statusSuccess : AppColors.statusDanger, fontWeight: FontWeight.bold, fontSize: 13)),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        _snack('Gagal memuat data stok.');
      }
    }
  }

  Future<void> _submitOrder() async {
    if (_selectedPackageId == null) {
      _snack('Pilih paket terlebih dahulu.');
      return;
    }
    final priceText = _finalPriceController.text.trim();
    if (priceText.isEmpty) {
      _snack('Masukkan harga akhir.');
      return;
    }
    if (_scheduledAt == null) {
      _snack('Tentukan jadwal pemakaman.');
      return;
    }
    final duration = double.tryParse(_durationController.text.trim());
    if (duration == null || duration < 0.5) {
      _snack('Masukkan estimasi durasi (minimal 0.5 jam).');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Order?'),
        content: const Text(
          'Order akan dikonfirmasi dan semua departemen akan mendapat notifikasi alarm. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await widget.repo.confirmOrder(widget.orderId, {
        'package_id': _selectedPackageId,
        'scheduled_at': _scheduledAt!.toIso8601String(),
        'estimated_duration_hours': duration,
        'final_price': double.tryParse(priceText) ?? 0,
        'so_notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'estimated_guests': int.tryParse(_guestsController.text.trim()),
      });

      if (res.data['success'] == true) {
        if (!mounted) return;
        _snack('Order dikonfirmasi! Semua tim sudah mendapat notifikasi.');
        Navigator.pop(context);
      } else {
        _snack(res.data['message'] ?? 'Gagal konfirmasi order.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              'Gagal Konfirmasi',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _snack('Gagal konfirmasi order. Periksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: _order?['order_number'] ?? 'Detail Order',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildAddonSection() {
    final List<dynamic> activeAddons = _order!['order_add_ons'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Layanan Tambahan'),
            TextButton.icon(
              onPressed: _showAddAddonModal,
              icon: const Icon(
                Icons.add_circle_outline,
                size: 16,
                color: _roleColor,
              ),
              label: const Text(
                'Tambah',
                style: TextStyle(color: _roleColor, fontSize: 12),
              ),
            ),
          ],
        ),
        if (activeAddons.isEmpty)
          const Center(
            child: Text(
              'Belum ada layanan tambahan.',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          )
        else
          ...activeAddons.map((oa) {
            final addon = oa['add_on_service'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassWidget(
                borderRadius: 12,
                blurSigma: 16,
                tint: AppColors.glassWhite,
                borderColor: AppColors.glassBorder,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_task,
                      color: AppColors.statusSuccess,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        addon?['name'] ?? '-',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _currency.format(
                        (double.tryParse(oa['price_at_time'].toString()) ?? 0) *
                            (oa['quantity'] ?? 1),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddAddonModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Layanan Tambahan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _addonsList.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final addon = _addonsList[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        addon['name'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        _currency.format(
                          double.tryParse(addon['price'].toString()) ?? 0,
                        ),
                      ),
                      trailing: _isAddingAddon
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: _roleColor,
                              ),
                              onPressed: () =>
                                  _submitAddon(addon['id'], setModalState),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAddon(String addonId, StateSetter setModalState) async {
    setModalState(() => _isAddingAddon = true);
    try {
      final res = await widget.repo.addOrderAddOn(widget.orderId, addonId);
      if (res.data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        _load();
        _snack('Layanan tambahan berhasil ditambahkan.');
      }
    } catch (e) {
      _snack('Gagal menambahkan layanan.');
    } finally {
      if (mounted) setModalState(() => _isAddingAddon = false);
    }
  }

  Widget _buildContent() {
    final order = _order!;
    final consumer = order['pic'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informasi Keluarga'),
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.person_outline,
                  'Nama',
                  order['pic_name'] ?? consumer?['name'] ?? '-',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.phone_outlined,
                  'HP',
                  order['pic_phone'] ?? consumer?['phone'] ?? '-',
                ),
                if (order['pickup_address'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.location_on_outlined,
                    'Lokasi Penjemputan',
                    order['pickup_address'],
                  ),
                ],
                if (order['deceased_name'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.person_off_outlined,
                    'Nama Almarhum',
                    order['deceased_name'],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Detail Order'),
          GlassWidget(
            borderRadius: 16,
            blurSigma: 16,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.tag,
                  'Nomor Order',
                  order['order_number'] ?? '-',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal',
                  _formatDate(order['created_at']),
                ),
                if (order['estimated_price'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.attach_money,
                    'Estimasi Harga',
                    _currency.format(
                      double.tryParse(order['estimated_price'].toString()) ?? 0,
                    ),
                  ),
                ],
                if (order['special_notes'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.notes_outlined,
                    'Catatan Konsumen',
                    order['special_notes'],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAddonSection(),
          const SizedBox(height: 24),

          // v1.14 — Quick actions for confirmed orders
          if (order['status'] != 'pending') ...[
            _sectionTitle('Dokumen & Formulir'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.description, size: 18, color: AppColors.roleSO),
                  label: const Text('Berkas Akta Kematian', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SoDeathCertScreen(orderId: widget.orderId, namaAlmarhum: order['deceased_name'] ?? '-'),
                  )),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_task, size: 18, color: AppColors.roleSO),
                  label: const Text('Persetujuan Tambahan', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SoExtraApprovalScreen(orderId: widget.orderId, namaAlmarhum: order['deceased_name'] ?? '-'),
                  )),
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, size: 18, color: AppColors.roleSO),
                  label: const Text('Surat Penerimaan', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SoAcceptanceLetterScreen(orderId: widget.orderId),
                  )),
                ),
                // v1.17 — WA deep link ke keluarga
                if (order['pic_phone'] != null)
                  ActionChip(
                    avatar: const Icon(Icons.chat, size: 18, color: Colors.green),
                    label: const Text('WA Keluarga', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.withValues(alpha: 0.08),
                    onPressed: () => WhatsAppService.contactForOrder(
                      phone: order['pic_phone'],
                      orderNumber: order['order_number'] ?? '',
                      role: 'Service Officer',
                    ),
                  ),
                // Gallery link dari Tukang Foto
                ActionChip(
                  avatar: const Icon(Icons.add_to_drive, size: 18, color: Color(0xFF4285F4)),
                  label: const Text('Galeri Foto', style: TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFF4285F4).withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GalleryLinkScreen(orderId: widget.orderId),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (order['status'] == 'pending') ...[
            _sectionTitle('Konfirmasi Order'),
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Paket',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPackageId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Pilih paket layanan',
                    ),
                    items: _packages.map((pkg) {
                      final price = _currency.format(
                        double.tryParse(pkg['base_price'].toString()) ?? 0,
                      );
                      final stockStatus = pkg['stock_status'] as String?;
                      final isLowStock = stockStatus == 'low_stock' || stockStatus == 'out_of_stock';
                      return DropdownMenuItem<String>(
                        value: pkg['id'],
                        enabled: stockStatus != 'out_of_stock',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pkg['name']} — $price',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: stockStatus == 'out_of_stock' ? AppColors.textHint : null,
                                ),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stockStatus == 'out_of_stock'
                                      ? AppColors.statusDanger.withValues(alpha: 0.12)
                                      : AppColors.statusWarning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stockStatus == 'out_of_stock' ? 'Habis' : 'Stok Tipis',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: stockStatus == 'out_of_stock'
                                        ? AppColors.statusDanger
                                        : AppColors.statusWarning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPackageId = val;
                        _selectedPackage = val == null
                            ? null
                            : _packages
                                  .cast<Map<String, dynamic>?>()
                                  .firstWhere(
                                    (p) => p?['id'] == val,
                                    orElse: () => null,
                                  );
                      });
                      if (val != null) {
                        _recalculateFinalPrice();
                      }
                    },
                  ),
                  // ── Selected package price card ──────────────────────────
                  if (_selectedPackage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _roleColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.roleSO,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPackage!['name'] ?? '-',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Harga Dasar Paket',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currency.format(
                              double.tryParse(
                                    _selectedPackage!['base_price'].toString(),
                                  ) ??
                                  0,
                            ),
                            style: const TextStyle(
                              color: AppColors.roleSO,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // ── Jadwal Pemakaman ─────────────────────────────────────
                  GestureDetector(
                    onTap: _pickSchedule,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSoft,
                        borderRadius: BorderRadius.circular(12),
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
                            color: _scheduledAt != null
                                ? _roleColor
                                : AppColors.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jadwal Pemakaman *',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _scheduledAt != null
                                      ? DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                          'id_ID',
                                        ).format(_scheduledAt!)
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
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _durationController,
                    label: 'Estimasi Durasi (jam) *',
                    icon: Icons.timer_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _finalPriceController,
                    label: 'Harga Akhir (Rp) * (Otomatis)',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _guestsController,
                    label: 'Estimasi Tamu',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _notesController,
                    label: 'Catatan SO (opsional)',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  // Stock Check Preview
                  if (_selectedPackageId != null)
                    OutlinedButton.icon(
                      onPressed: () => _showStockPreview(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.roleGudang,
                        side: const BorderSide(color: AppColors.roleGudang),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.inventory_outlined, size: 18),
                      label: const Text('Cek Ketersediaan Stok'),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSubmitting ? 'Mengonfirmasi...' : 'Konfirmasi Order',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _sectionTitle('Detail Pelaksanaan'),
            GlassWidget(
              borderRadius: 16,
              blurSigma: 16,
              tint: AppColors.glassWhite,
              borderColor: AppColors.glassBorder,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPackage != null)
                    _infoRow(
                      Icons.inventory_2_outlined,
                      'Paket Terpilih',
                      _selectedPackage!['name'] ?? '-',
                    ),
                  if (_selectedPackage != null) const SizedBox(height: 8),
                  _infoRow(
                    Icons.calendar_month_outlined,
                    'Jadwal Pemakaman',
                    _formatDate(order['scheduled_at']),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.timer_outlined,
                    'Estimasi Durasi',
                    '${order['estimated_duration_hours'] ?? '-'} Jam',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.payments_outlined,
                    'Harga Akhir',
                    _currency.format(
                      double.tryParse(
                            order['final_price']?.toString() ?? '0',
                          ) ??
                          0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.people_outline,
                    'Estimasi Tamu',
                    '${order['estimated_guests'] ?? '-'} Orang',
                  ),
                  if (order['so_notes'] != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.notes_outlined,
                      'Catatan SO',
                      order['so_notes'],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textHint,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
        labelText: label,
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }
}
