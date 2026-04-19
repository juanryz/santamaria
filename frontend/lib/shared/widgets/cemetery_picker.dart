import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Reusable searchable picker for cemeteries / crematoriums.
///
/// Usage:
/// ```dart
/// CemeteryPicker(
///   onSelected: (id, name) { ... },
///   city: 'Semarang', // optional filter
/// )
/// ```
class CemeteryPicker extends StatefulWidget {
  final void Function(String id, String name) onSelected;
  final String? city;
  final String? initialId;
  final String? initialName;
  final bool isAdmin;

  const CemeteryPicker({
    super.key,
    required this.onSelected,
    this.city,
    this.initialId,
    this.initialName,
    this.isAdmin = false,
  });

  @override
  State<CemeteryPicker> createState() => _CemeteryPickerState();
}

class _CemeteryPickerState extends State<CemeteryPicker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _api = ApiClient();
  final _link = LayerLink();

  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _controller.text = widget.initialName!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().length >= 2) {
        _search(query.trim());
      } else {
        _removeOverlay();
        setState(() => _results = []);
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{'search': query};
      if (widget.city != null) params['city'] = widget.city;
      final res = await _api.dio.get('/cemeteries', queryParameters: params);
      if (res.data['success'] == true) {
        _results = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      } else {
        _results = [];
      }
    } catch (_) {
      _results = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _showResultsOverlay();
    }
  }

  void _showResultsOverlay() {
    _removeOverlay();
    if (!_focusNode.hasFocus) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _buildDropdownContent(),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  double _getFieldWidth() {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size.width ?? 300;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final items = <Widget>[];

    if (_results.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tidak ditemukan', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    } else {
      for (final c in _results) {
        final type = c['type'] as String? ?? '';
        final typeColor = switch (type) {
          'krematorium' => Colors.deepOrange,
          'umum' => Colors.green,
          'khusus' => Colors.blue,
          _ => Colors.grey,
        };

        items.add(
          InkWell(
            onTap: () {
              _controller.text = c['name'] ?? '';
              widget.onSelected(c['id'].toString(), c['name'] ?? '');
              _removeOverlay();
              _focusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (c['city'] != null || c['address'] != null)
                          Text(
                            [c['city'], c['address']].where((e) => e != null).join(' - '),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (widget.isAdmin) {
      items.add(const Divider(height: 1));
      items.add(
        InkWell(
          onTap: () {
            _removeOverlay();
            _focusNode.unfocus();
            _showCreateDialog();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 16, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Text('Tambah Baru', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: items);
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String selectedType = 'umum';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Pemakaman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pemakaman')),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Kota')),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: const [
                  DropdownMenuItem(value: 'umum', child: Text('Umum')),
                  DropdownMenuItem(value: 'khusus', child: Text('Khusus')),
                  DropdownMenuItem(value: 'krematorium', child: Text('Krematorium')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v ?? 'umum'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'cemetery_type': selectedType,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      final res = await _api.dio.post('/admin/cemeteries', data: result);
      if (res.data['success'] == true) {
        final created = res.data['data'];
        _controller.text = created['name'] ?? result['name']!;
        widget.onSelected(created['id'].toString(), created['name'] ?? result['name']!);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      String msg = 'Gagal menambahkan pemakaman';
      if (body is Map) {
        if (body['message'] is String) msg = body['message'];
        if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
          final first = (body['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) msg = first.first.toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan pemakaman')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: const InputDecoration(
          labelText: 'Pemakaman / Krematorium',
          prefixIcon: Icon(Icons.park_outlined),
          hintText: 'Cari pemakaman...',
        ),
      ),
    );
  }
}
