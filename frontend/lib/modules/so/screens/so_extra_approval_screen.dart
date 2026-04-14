import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class SoExtraApprovalScreen extends StatefulWidget {
  final String orderId;
  final String namaAlmarhum;
  const SoExtraApprovalScreen({super.key, required this.orderId, required this.namaAlmarhum});

  @override
  State<SoExtraApprovalScreen> createState() => _SoExtraApprovalScreenState();
}

class _SoExtraApprovalScreenState extends State<SoExtraApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;

  final _pjNamaCtrl = TextEditingController();
  final _pjAlamatCtrl = TextEditingController();
  final _pjTelpCtrl = TextEditingController();
  final _pjHubCtrl = TextEditingController();
  final List<Map<String, TextEditingController>> _lines = [
    {'keterangan': TextEditingController(), 'biaya': TextEditingController()},
  ];
  final _signatureStrokes = <List<Offset>>[];
  List<Offset>? _currentStroke;

  void _addLine() {
    setState(() => _lines.add({'keterangan': TextEditingController(), 'biaya': TextEditingController()}));
  }

  void _removeLine(int i) {
    if (_lines.length > 1) setState(() => _lines.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signatureStrokes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanda tangan wajib diisi')));
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final lines = _lines.map((l) => {
        'keterangan': l['keterangan']!.text,
        'biaya': double.tryParse(l['biaya']!.text) ?? 0,
      }).toList();

      final signatureBase64 = await _exportSignatureBase64();

      final payload = <String, dynamic>{
        'nama_almarhum': widget.namaAlmarhum,
        'pj_nama': _pjNamaCtrl.text,
        'pj_alamat': _pjAlamatCtrl.text,
        'pj_no_telp': _pjTelpCtrl.text,
        'pj_hub_alm': _pjHubCtrl.text,
        'tanggal': DateTime.now().toIso8601String().split('T')[0],
        'lines': lines,
      };
      if (signatureBase64 != null) payload['signature'] = signatureBase64;
      await _api.dio.post('/so/orders/${widget.orderId}/extra-approvals', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Persetujuan tambahan dibuat')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Persetujuan Tambahan', accentColor: AppColors.roleSO),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassWidget(
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Penanggung Jawab Keluarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pjNamaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama PJ *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _pjAlamatCtrl, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(controller: _pjTelpCtrl, decoration: const InputDecoration(labelText: 'No. Telp', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextFormField(controller: _pjHubCtrl, decoration: const InputDecoration(labelText: 'Hubungan dgn Almarhum', border: OutlineInputBorder())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassWidget(
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Item Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        IconButton(icon: const Icon(Icons.add_circle, color: AppColors.roleSO), onPressed: _addLine),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_lines.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _lines[i]['keterangan'],
                                decoration: InputDecoration(labelText: 'Item ${i + 1}', border: const OutlineInputBorder()),
                                validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _lines[i]['biaya'],
                                decoration: const InputDecoration(labelText: 'Biaya', border: OutlineInputBorder(), prefixText: 'Rp '),
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                              ),
                            ),
                            if (_lines.length > 1)
                              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), onPressed: () => _removeLine(i)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassWidget(
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Tanda Tangan PJ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        TextButton(
                          onPressed: () => setState(() { _signatureStrokes.clear(); _currentStroke = null; }),
                          child: const Text('Hapus', style: TextStyle(color: AppColors.statusDanger, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: GestureDetector(
                        onPanStart: (d) => setState(() { _currentStroke = [d.localPosition]; _signatureStrokes.add(_currentStroke!); }),
                        onPanUpdate: (d) => setState(() => _currentStroke?.add(d.localPosition)),
                        onPanEnd: (_) => setState(() => _currentStroke = null),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _SignaturePainter(_signatureStrokes),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.roleSO, minimumSize: const Size.fromHeight(48)),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan & Tanda Tangan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pjNamaCtrl.dispose();
    _pjAlamatCtrl.dispose();
    _pjTelpCtrl.dispose();
    _pjHubCtrl.dispose();
    for (final l in _lines) {
      l['keterangan']?.dispose();
      l['biaya']?.dispose();
    }
    super.dispose();
  }

  Future<String?> _exportSignatureBase64() async {
    if (_signatureStrokes.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _SignaturePainter(_signatureStrokes);
    painter.paint(canvas, const Size(400, 150));
    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 150);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(Uint8List.view(byteData.buffer));
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
