import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class GudangReceiveScreen extends StatefulWidget {
  const GudangReceiveScreen({super.key});

  @override
  State<GudangReceiveScreen> createState() => _GudangReceiveScreenState();
}

class _GudangReceiveScreenState extends State<GudangReceiveScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _requests = [];

  static const _roleColor = AppColors.roleGudang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/gudang/procurement-requests',
        queryParameters: {
          'status': 'purchasing_approved,goods_shipped',
        },
      );
      if (res.data['success'] == true) {
        _requests = List<dynamic>.from(res.data['data'] ?? []);
      } else if (res.data['data'] != null) {
        _requests = List<dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Terima Barang dari Supplier',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.statusSuccess,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada barang yang perlu diterima',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (_, i) =>
                        _RequestCard(
                          request: _requests[i],
                          onReceived: _loadData,
                        ),
                  ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final dynamic request;
  final VoidCallback onReceived;

  const _RequestCard({required this.request, required this.onReceived});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final ApiClient _api = ApiClient();
  static const _roleColor = AppColors.roleGudang;

  void _showReceiveDialog() {
    final qtyCtrl = TextEditingController(
      text: (widget.request['quantity'] ?? 1).toString(),
    );
    String condition = 'baik';
    final notesCtrl = TextEditingController();
    File? photoFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Penerimaan Barang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.request['item_name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Diterima',
                    helperText:
                        'Dipesan: ${widget.request['quantity'] ?? '-'}',
                    prefixIcon:
                        const Icon(Icons.inventory_2_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kondisi Barang',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _conditionChip('baik', 'Baik', Icons.check_circle,
                        AppColors.statusSuccess, condition, (v) {
                      setSheet(() => condition = v);
                    }),
                    _conditionChip('rusak', 'Ada Kerusakan', Icons.warning,
                        AppColors.statusWarning, condition, (v) {
                      setSheet(() => condition = v);
                    }),
                    _conditionChip('kurang', 'Kurang', Icons.remove_circle,
                        AppColors.statusDanger, condition, (v) {
                      setSheet(() => condition = v);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: Icon(Icons.notes, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final xf = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1280,
                      imageQuality: 80,
                    );
                    if (xf != null) {
                      setSheet(() => photoFile = File(xf.path));
                    }
                  },
                  icon: Icon(
                    photoFile != null
                        ? Icons.check_circle
                        : Icons.camera_alt,
                    color: photoFile != null
                        ? AppColors.statusSuccess
                        : _roleColor,
                    size: 18,
                  ),
                  label: Text(
                    photoFile != null
                        ? 'Foto terlampir'
                        : 'Foto Barang Diterima',
                    style: TextStyle(
                      color: photoFile != null
                          ? AppColors.statusSuccess
                          : _roleColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (photoFile != null
                              ? AppColors.statusSuccess
                              : _roleColor)
                          .withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheet(() => isSaving = true);
                            try {
                              final id = widget.request['id'];
                              final formData = FormData.fromMap({
                                'received_quantity':
                                    int.tryParse(qtyCtrl.text.trim()) ?? 0,
                                'condition': condition,
                                'notes': notesCtrl.text.trim(),
                                if (photoFile != null)
                                  'photo': await MultipartFile.fromFile(
                                    photoFile!.path,
                                  ),
                              });
                              await _api.dio.put(
                                '/gudang/procurement-requests/$id/receive',
                                data: formData,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Barang berhasil dikonfirmasi diterima',
                                    ),
                                    backgroundColor:
                                        AppColors.statusSuccess,
                                  ),
                                );
                                widget.onReceived();
                              }
                            } catch (_) {
                              setSheet(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Gagal mengkonfirmasi penerimaan',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _roleColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Konfirmasi Diterima',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conditionChip(
    String value,
    String label,
    IconData icon,
    Color color,
    String current,
    ValueChanged<String> onTap,
  ) {
    final isSelected = current == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : color,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onSelected: (_) => onTap(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final name = r['item_name'] as String? ?? '-';
    final reqNumber = r['request_number'] as String? ?? '-';
    final qty = r['quantity'] ?? '-';
    final supplier = r['awarded_supplier_name'] as String? ??
        r['supplier_name'] as String? ??
        '-';
    final tracking = r['tracking_number'] as String?;
    final status = r['status'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 10,
        tint: AppColors.glassWhite,
        borderColor: _roleColor.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _roleColor.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: _roleColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        reqNumber,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GlassStatusBadge(
                  label: status,
                  color: _roleColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow(Icons.store, 'Supplier: $supplier'),
            _detailRow(Icons.inventory_2, 'Qty dipesan: $qty'),
            if (tracking != null)
              _detailRow(Icons.local_shipping, 'Resi: $tracking'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showReceiveDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text(
                  'Barang Diterima',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
