import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SoAcceptanceLetterScreen extends StatefulWidget {
  final String orderId;

  const SoAcceptanceLetterScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<SoAcceptanceLetterScreen> createState() =>
      _SoAcceptanceLetterScreenState();
}

class _SoAcceptanceLetterScreenState extends State<SoAcceptanceLetterScreen> {
  static const _roleColor = AppColors.roleSO;

  final _api = ApiClient();
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Map<String, dynamic>? _order;
  Map<String, dynamic>? _letter;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _error;

  final _signaturePJKey = GlobalKey<_SignaturePadState>();
  final _signatureSMKey = GlobalKey<_SignaturePadState>();
  final _signatureSaksiKey = GlobalKey<_SignaturePadState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.dio.get(
        '/so/orders/${widget.orderId}/acceptance-letter',
      );
      final data = response.data;
      setState(() {
        _order = data['order'] as Map<String, dynamic>?;
        _letter = data['letter'] as Map<String, dynamic>?;
        _isSubmitted = _letter?['signed'] == true;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message']?.toString() ??
            'Gagal memuat data. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<String?> _signatureToBase64(GlobalKey<_SignaturePadState> key) async {
    final state = key.currentState;
    if (state == null || state.isEmpty) return null;
    final image = await state.toImage();
    if (image == null) return null;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(byteData.buffer.asUint8List());
  }

  Future<void> _submit() async {
    // Capture messenger before any awaits to avoid async-gap lint
    final messenger = ScaffoldMessenger.of(context);
    final pjBase64 = await _signatureToBase64(_signaturePJKey);
    final smBase64 = await _signatureToBase64(_signatureSMKey);

    if (pjBase64 == null || smBase64 == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tanda tangan PJ dan SM Officer wajib diisi.',
          ),
        ),
      );
      return;
    }

    final saksiBase64 = await _signatureToBase64(_signatureSaksiKey);

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        'signature_pj': pjBase64,
        'signature_sm': smBase64,
      };
      if (saksiBase64 != null) payload['signature_saksi'] = saksiBase64;
      await _api.dio.post(
        '/so/orders/${widget.orderId}/acceptance-letter',
        data: payload,
      );
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surat Penerimaan Layanan berhasil disimpan.'),
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message']?.toString() ??
                  'Gagal menyimpan. Silakan coba lagi.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/so/orders/${widget.orderId}/acceptance-letter/pdf',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka URL PDF.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka PDF: $e')),
        );
      }
    }
  }

  void _shareWhatsApp() {
    final order = _order;
    if (order == null) return;
    final phone = order['pic_phone']?.toString() ?? '';
    final orderNumber = order['order_number']?.toString() ?? widget.orderId;
    WhatsAppService.openChat(
      phone: phone,
      message:
          'Surat Penerimaan Layanan untuk order $orderNumber telah ditandatangani.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Surat Penerimaan Layanan',
        accentColor: _roleColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionPJ(order),
          const SizedBox(height: 12),
          _buildSectionAlmarhum(order),
          const SizedBox(height: 12),
          _buildSectionPaket(order),
          const SizedBox(height: 12),
          _buildSectionLokasi(order),
          const SizedBox(height: 12),
          _buildSectionCatatan(order),
          const SizedBox(height: 12),
          _buildSectionTerms(),
          const SizedBox(height: 24),
          _buildSignatureSection(
            label: 'Tanda Tangan PJ (Keluarga)',
            padKey: _signaturePJKey,
            existingBase64: _letter?['signature_pj']?.toString(),
          ),
          const SizedBox(height: 16),
          _buildSignatureSection(
            label: 'Tanda Tangan SM Officer (SO)',
            padKey: _signatureSMKey,
            existingBase64: _letter?['signature_sm']?.toString(),
          ),
          const SizedBox(height: 16),
          _buildSignatureSection(
            label: 'Tanda Tangan Saksi (Opsional)',
            padKey: _signatureSaksiKey,
            existingBase64: _letter?['signature_saksi']?.toString(),
          ),
          const SizedBox(height: 24),
          if (!_isSubmitted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Menyimpan...' : 'Simpan & Tandatangani',
                ),
              ),
            ),
          if (_isSubmitted) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Kirim via WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return GlassWidget(
      borderRadius: 16,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _roleColor,
            ),
          ),
          const Divider(height: 16),
          ...children,
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
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPJ(Map<String, dynamic> order) {
    return _sectionCard(
      title: '1. Penanggung Jawab (PJ)',
      children: [
        _infoRow('Nama PJ', order['pic_name']?.toString() ?? '-'),
        _infoRow('No. Telepon', order['pic_phone']?.toString() ?? '-'),
        _infoRow('Alamat', order['pic_address']?.toString() ?? '-'),
        _infoRow(
          'Hubungan',
          order['pic_relationship']?.toString() ?? '-',
        ),
      ],
    );
  }

  Widget _buildSectionAlmarhum(Map<String, dynamic> order) {
    return _sectionCard(
      title: '2. Data Almarhum/Almarhumah',
      children: [
        _infoRow('Nama', order['deceased_name']?.toString() ?? '-'),
        _infoRow(
          'Tanggal Wafat',
          _formatDate(order['deceased_date']?.toString()),
        ),
        _infoRow('Usia', order['deceased_age']?.toString() ?? '-'),
        _infoRow('Agama', order['deceased_religion']?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildSectionPaket(Map<String, dynamic> order) {
    final packageName = order['package_name']?.toString() ?? '-';
    final totalPrice = order['total_price'];
    final formattedPrice =
        totalPrice != null ? _currency.format(num.tryParse(totalPrice.toString()) ?? 0) : '-';
    final addons = order['addons'] as List<dynamic>? ?? [];

    return _sectionCard(
      title: '3. Paket Layanan',
      children: [
        _infoRow('Paket', packageName),
        _infoRow('Total Harga', formattedPrice),
        if (addons.isNotEmpty)
          _infoRow(
            'Tambahan',
            addons
                .map((a) => a['name']?.toString() ?? '')
                .where((n) => n.isNotEmpty)
                .join(', '),
          ),
      ],
    );
  }

  Widget _buildSectionLokasi(Map<String, dynamic> order) {
    return _sectionCard(
      title: '4. Lokasi',
      children: [
        _infoRow('Rumah Duka', order['funeral_home']?.toString() ?? '-'),
        _infoRow('Gereja', order['church']?.toString() ?? '-'),
        _infoRow('Pemakaman', order['cemetery']?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildSectionCatatan(Map<String, dynamic> order) {
    final notes = order['notes']?.toString() ?? '-';
    return _sectionCard(
      title: '5. Catatan Khusus',
      children: [
        Text(
          notes,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTerms() {
    return _sectionCard(
      title: '6. Syarat & Ketentuan',
      children: const [
        Text(
          'Dengan menandatangani surat ini, Penanggung Jawab menyatakan telah '
          'memahami dan menyetujui seluruh layanan yang akan diberikan oleh '
          'Santa Maria sesuai dengan paket yang dipilih. Segala perubahan atau '
          'penambahan layanan di luar paket akan dikenakan biaya tambahan yang '
          'akan dikomunikasikan terlebih dahulu. Santa Maria akan memberikan '
          'layanan secara profesional dan penuh tanggung jawab.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection({
    required String label,
    required GlobalKey<_SignaturePadState> padKey,
    String? existingBase64,
  }) {
    final hasExisting = existingBase64 != null && existingBase64.isNotEmpty;

    return GlassWidget(
      borderRadius: 16,
      blurSigma: 16,
      tint: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _roleColor,
                ),
              ),
              if (!_isSubmitted && !hasExisting)
                GestureDetector(
                  onTap: () => padKey.currentState?.clear(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasExisting && _isSubmitted)
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: Image.memory(
                  base64Decode(existingBase64),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
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
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

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
    final context = this.context;
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
      onPanStart: (details) {
        setState(() {
          _currentStroke = [details.localPosition];
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentStroke?.add(details.localPosition);
        });
      },
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
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, paint);
    }
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
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
