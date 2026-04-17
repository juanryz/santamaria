import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class PurchasingSupplierDetailScreen extends StatefulWidget {
  final String transactionId;

  const PurchasingSupplierDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<PurchasingSupplierDetailScreen> createState() =>
      _PurchasingSupplierDetailScreenState();
}

class _PurchasingSupplierDetailScreenState
    extends State<PurchasingSupplierDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _txn = {};

  static const _roleColor = AppColors.rolePurchasing;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get(
        '/finance/supplier-transactions/${widget.transactionId}',
      );
      if (res.data['success'] == true) {
        _txn = Map<String, dynamic>.from(res.data['data'] ?? {});
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    return _dateFormat.format(dt);
  }

  Color _shipmentColor(String? s) {
    switch (s) {
      case 'goods_received':
        return AppColors.statusSuccess;
      case 'shipped':
        return AppColors.statusInfo;
      case 'pending_shipment':
        return AppColors.statusWarning;
      case 'partial_received':
        return Colors.orange;
      default:
        return AppColors.textHint;
    }
  }

  String _shipmentLabel(String? s) {
    switch (s) {
      case 'pending_shipment':
        return 'Menunggu Pengiriman';
      case 'shipped':
        return 'Sudah Dikirim';
      case 'goods_received':
        return 'Barang Diterima';
      case 'partial_received':
        return 'Diterima Sebagian';
      default:
        return s ?? '-';
    }
  }

  String _paymentLabel(String? s) {
    switch (s) {
      case 'unpaid':
        return 'Belum Dibayar';
      case 'paid':
        return 'Sudah Dibayar';
      default:
        return s ?? '-';
    }
  }

  Color _paymentColor(String? s) {
    return s == 'paid' ? AppColors.statusSuccess : AppColors.statusDanger;
  }

  Future<void> _showPayDialog() async {
    final amountCtrl = TextEditingController(
      text: _toDouble(_txn['agreed_total']).toStringAsFixed(0),
    );
    File? receiptFile;
    bool isSaving = false;

    await showModalBottomSheet(
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
                'Bayar Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Supplier: ${_txn['supplier_name'] ?? '-'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Bayar (Rp)',
                  prefixIcon: Icon(Icons.payments, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final xf = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1280,
                    imageQuality: 80,
                  );
                  if (xf != null) {
                    setSheet(() => receiptFile = File(xf.path));
                  }
                },
                icon: Icon(
                  receiptFile != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: receiptFile != null
                      ? AppColors.statusSuccess
                      : _roleColor,
                  size: 18,
                ),
                label: Text(
                  receiptFile != null
                      ? 'Bukti terpilih'
                      : 'Upload Bukti Transfer',
                  style: TextStyle(
                    color: receiptFile != null
                        ? AppColors.statusSuccess
                        : _roleColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: (receiptFile != null
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
                          final amount =
                              double.tryParse(amountCtrl.text.trim());
                          if (amount == null || amount <= 0) return;

                          setSheet(() => isSaving = true);
                          try {
                            final formData = FormData.fromMap({
                              'method': 'transfer',
                              'amount': amount,
                              if (receiptFile != null)
                                'receipt_photo':
                                    await MultipartFile.fromFile(
                                  receiptFile!.path,
                                ),
                            });
                            await _api.dio.put(
                              '/finance/supplier-transactions/${widget.transactionId}/pay',
                              data: formData,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Pembayaran berhasil dicatat'),
                                  backgroundColor:
                                      AppColors.statusSuccess,
                                ),
                              );
                              _loadData();
                            }
                          } catch (_) {
                            setSheet(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal memproses pembayaran'),
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusSuccess,
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
                          'Konfirmasi Bayar',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Detail Transaksi Supplier',
        accentColor: _roleColor,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _txn.isEmpty
                ? const Center(
                    child: Text(
                      'Data tidak ditemukan',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildTimeline(),
                      const SizedBox(height: 16),
                      if (_txn['shipment_status'] == 'goods_received' &&
                          _txn['payment_status'] != 'paid')
                        _buildPayButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final shipment = _txn['shipment_status'] as String? ?? 'pending_shipment';
    final payment = _txn['payment_status'] as String? ?? 'unpaid';

    return GlassWidget(
      borderRadius: 18,
      blurSigma: 12,
      tint: AppColors.glassWhite,
      borderColor: _roleColor.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: _roleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _txn['transaction_number'] as String? ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow('Barang', _txn['item_name'] ?? '-'),
          _infoRow('Supplier', _txn['supplier_name'] ?? '-'),
          _infoRow(
            'Harga Disepakati',
            _currency.format(_toDouble(_txn['agreed_total'])),
          ),
          _infoRow(
            'Qty',
            '${_txn['agreed_quantity'] ?? '-'} unit',
          ),
          if (_txn['tracking_number'] != null)
            _infoRow('No. Resi', _txn['tracking_number'].toString()),
          const SizedBox(height: 12),
          Row(
            children: [
              GlassStatusBadge(
                label: _shipmentLabel(shipment),
                color: _shipmentColor(shipment),
              ),
              const SizedBox(width: 8),
              GlassStatusBadge(
                label: _paymentLabel(payment),
                color: _paymentColor(payment),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Purchasing Approved',
        date: _fmtDate(_txn['purchasing_approved_at']),
        isDone: _txn['purchasing_approved_at'] != null,
      ),
      _TimelineStep(
        label: 'Supplier Kirim Barang',
        date: _fmtDate(_txn['shipped_at']),
        isDone: _txn['shipped_at'] != null,
      ),
      _TimelineStep(
        label: 'Barang Diterima Gudang',
        date: _fmtDate(_txn['received_at']),
        isDone: _txn['received_at'] != null,
      ),
      _TimelineStep(
        label: 'Pembayaran ke Supplier',
        date: _txn['payment_status'] == 'paid'
            ? _fmtDate(_txn['payment_date'] ?? _txn['updated_at'])
            : '-',
        isDone: _txn['payment_status'] == 'paid',
      ),
    ];

    return GlassWidget(
      borderRadius: 16,
      blurSigma: 10,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline Transaksi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return _buildTimelineStep(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(_TimelineStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isDone
                      ? AppColors.statusSuccess
                      : AppColors.textHint.withValues(alpha: 0.3),
                ),
                child: Icon(
                  step.isDone ? Icons.check : Icons.circle,
                  size: 14,
                  color: step.isDone ? Colors.white : AppColors.textHint,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isDone
                        ? AppColors.statusSuccess.withValues(alpha: 0.4)
                        : AppColors.textHint.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: step.isDone
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.date,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showPayDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusSuccess,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.payments, size: 20),
        label: const Text(
          'Bayar Supplier',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final String date;
  final bool isDone;

  const _TimelineStep({
    required this.label,
    required this.date,
    required this.isDone,
  });
}
