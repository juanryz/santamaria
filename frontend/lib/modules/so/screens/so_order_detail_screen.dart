import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/so_repository.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import 'so_death_cert_screen.dart';
import 'so_extra_approval_screen.dart';
import 'so_acceptance_letter_screen.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../tukang_foto/screens/gallery_link_screen.dart';
import 'so_amendment_screen.dart';
import 'custom_service_phases_screen.dart';
import 'out_of_city_transport_screen.dart';
import 'musician_sessions_screen.dart';
import 'vendor_assignment_screen.dart';
import '../../../shared/screens/location_presence_screen.dart';

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
  bool _isAddingAddon = false;
  String? _error;

  String? _selectedPackageId;
  Map<String, dynamic>? _selectedPackage;

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
        setState(() => _order = order);
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
    } catch (e) {
      setState(() => _error = 'Gagal memuat data order.');
    } finally {
      setState(() => _isLoading = false);
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
                // v1.40 — Layanan Custom (multi rumah duka)
                ActionChip(
                  avatar: const Icon(Icons.place, size: 18, color: AppColors.roleSO),
                  label: const Text('Layanan Custom', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CustomServicePhasesScreen(
                      orderId: widget.orderId,
                      orderNumber: order['order_number'] ?? '-',
                    ),
                  )),
                ),
                // v1.39 — Transport Luar Kota
                ActionChip(
                  avatar: const Icon(Icons.directions_bus, size: 18, color: AppColors.roleSO),
                  label: const Text('Transport Luar Kota', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OutOfCityTransportScreen(
                      orderId: widget.orderId,
                      orderNumber: order['order_number'] ?? '-',
                    ),
                  )),
                ),
                // v1.40 — Sesi Musisi
                ActionChip(
                  avatar: const Icon(Icons.music_note, size: 18, color: AppColors.roleSO),
                  label: const Text('Sesi Musisi', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MusicianSessionsScreen(
                      orderId: widget.orderId,
                      orderNumber: order['order_number'] ?? '-',
                    ),
                  )),
                ),
                // v1.24/v1.40 — Vendor Assignments (Internal + External)
                ActionChip(
                  avatar: const Icon(Icons.people_outline, size: 18, color: AppColors.roleSO),
                  label: const Text('Tim Vendor', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VendorAssignmentScreen(
                      orderId: widget.orderId,
                      orderNumber: order['order_number'] ?? '-',
                    ),
                  )),
                ),
                // v1.40 — Presensi Lokasi (check-in/out di rumah duka)
                ActionChip(
                  avatar: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.roleSO),
                  label: const Text('Presensi Lokasi', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LocationPresenceScreen(
                      orderId: widget.orderId,
                      orderNumber: order['order_number'] ?? '-',
                    ),
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
                // Amendment — visible when order is active
                if (['confirmed', 'in_progress', 'preparing', 'ready_to_dispatch',
                     'driver_assigned', 'delivering_equipment', 'equipment_arrived',
                     'picking_up_body', 'body_arrived', 'in_ceremony']
                    .contains(order['status']))
                  ActionChip(
                    avatar: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.roleSO),
                    label: const Text('Amendment', style: TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.roleSO.withValues(alpha: 0.08),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SOAmendmentScreen(
                        orderId: widget.orderId,
                        orderNumber: order['order_number'] ?? '',
                      ),
                    )),
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
