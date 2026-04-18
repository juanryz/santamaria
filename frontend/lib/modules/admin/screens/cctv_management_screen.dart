import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.39 — Super Admin CRUD CCTV cameras.
class CctvManagementScreen extends StatefulWidget {
  const CctvManagementScreen({super.key});

  @override
  State<CctvManagementScreen> createState() => _CctvManagementScreenState();
}

class _CctvManagementScreenState extends State<CctvManagementScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _cameras = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/super-admin/cctv');
      if (!mounted) return;
      if (res.data['success'] == true) {
        final d = res.data['data'];
        setState(() =>
            _cameras = List<dynamic>.from(d is Map ? (d['data'] ?? []) : d));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat daftar kamera.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _CctvForm(existing: existing)),
    );
    if (result == true) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> cam) async {
    try {
      final res = await _api.dio.put('/super-admin/cctv/${cam['id']}/toggle');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Status diubah'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {}
  }

  Future<void> _delete(Map<String, dynamic> cam) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Hapus Kamera?',
      message: '${cam['camera_label']} akan dihapus.',
      confirmLabel: 'Hapus',
    );
    if (!ok) return;

    try {
      final res = await _api.dio.delete('/super-admin/cctv/${cam['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Kamera dihapus'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Kelola CCTV',
        accentColor: AppColors.brandPrimary,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Kamera', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _cameras.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.videocam_off_outlined,
                        title: 'Belum Ada Kamera',
                        subtitle: 'Tekan tombol + untuk menambah kamera.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cameras.length,
                        itemBuilder: (c, i) =>
                            _card(_cameras[i] as Map<String, dynamic>),
                      ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> cam) {
    final isActive = cam['is_active'] == true;
    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: (isActive ? AppColors.statusSuccess : AppColors.textHint)
          .withOpacity(0.25),
      onTap: () => _openForm(cam),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_locationIcon(cam['location_type'] ?? ''),
                  color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cam['camera_label'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(_locationLabel(cam['location_type'] ?? ''),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GlassStatusBadge(
                label: isActive ? 'Aktif' : 'Nonaktif',
                color: isActive
                    ? AppColors.statusSuccess
                    : AppColors.textHint,
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'toggle') _toggleActive(cam);
                  if (v == 'delete') _delete(cam);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.language,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(cam['ip_address'] ?? '-',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace')),
              ),
              Text(((cam['stream_type'] ?? 'rtsp') as String).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary)),
            ],
          ),
          if ((cam['area_detail'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(cam['area_detail'],
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  IconData _locationIcon(String t) => switch (t) {
        'kantor' => Icons.business,
        'gudang' => Icons.warehouse,
        'lafiore' => Icons.local_florist,
        'parkiran' => Icons.local_parking,
        'pos_security' => Icons.security,
        _ => Icons.place,
      };

  String _locationLabel(String t) => switch (t) {
        'kantor' => 'Kantor',
        'gudang' => 'Gudang',
        'lafiore' => 'Lafiore',
        'parkiran' => 'Parkiran',
        'pos_security' => 'Pos Security',
        _ => t,
      };

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
}

// ─────────────────────────────────────────────────────────────
// CCTV Form (create/edit)
// ─────────────────────────────────────────────────────────────

class _CctvForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _CctvForm({this.existing});

  @override
  State<_CctvForm> createState() => _CctvFormState();
}

class _CctvFormState extends State<_CctvForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _labelCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String _location = 'kantor';
  String _streamType = 'rtsp';
  bool _isActive = true;
  bool _saving = false;
  bool _loadingDetail = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _labelCtrl.text = widget.existing!['camera_label'] ?? '';
      _ipCtrl.text = widget.existing!['ip_address'] ?? '';
      _urlCtrl.text = widget.existing!['stream_url'] ?? '';
      _userCtrl.text = widget.existing!['username'] ?? '';
      _areaCtrl.text = widget.existing!['area_detail'] ?? '';
      _location = widget.existing!['location_type'] ?? 'kantor';
      _streamType = widget.existing!['stream_type'] ?? 'rtsp';
      _isActive = widget.existing!['is_active'] ?? true;
      _loadPassword();
    }
  }

  Future<void> _loadPassword() async {
    setState(() => _loadingDetail = true);
    try {
      final res =
          await _api.dio.get('/super-admin/cctv/${widget.existing!['id']}');
      if (res.data['success'] == true) {
        final d = res.data['data'];
        setState(() => _passCtrl.text = d['password'] ?? '');
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDetail = false);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _ipCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'camera_label': _labelCtrl.text.trim(),
      'location_type': _location,
      'ip_address': _ipCtrl.text.trim(),
      'stream_url': _urlCtrl.text.trim(),
      'username': _userCtrl.text.trim().isEmpty ? null : _userCtrl.text.trim(),
      'password': _passCtrl.text.trim().isEmpty ? null : _passCtrl.text.trim(),
      'stream_type': _streamType,
      'area_detail':
          _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      'is_active': _isActive,
    };

    try {
      final res = widget.existing != null
          ? await _api.dio
              .put('/super-admin/cctv/${widget.existing!['id']}', data: body)
          : await _api.dio.post('/super-admin/cctv', data: body);
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kamera tersimpan'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
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
            content: Text('Gagal menyimpan kamera'),
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
        title: widget.existing != null ? 'Edit Kamera' : 'Tambah Kamera',
        accentColor: AppColors.brandPrimary,
        showBack: true,
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(_labelCtrl, 'Nama Kamera', Icons.label,
                      required: true,
                      hint: 'cth: CCTV Pintu Depan Kantor'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _location,
                    decoration: _dec(Icons.place, label: 'Lokasi'),
                    items: const [
                      DropdownMenuItem(value: 'kantor', child: Text('Kantor')),
                      DropdownMenuItem(value: 'gudang', child: Text('Gudang')),
                      DropdownMenuItem(
                          value: 'lafiore', child: Text('Lafiore')),
                      DropdownMenuItem(
                          value: 'parkiran', child: Text('Parkiran')),
                      DropdownMenuItem(
                          value: 'pos_security',
                          child: Text('Pos Security')),
                    ],
                    onChanged: (v) => setState(() => _location = v ?? 'kantor'),
                  ),
                  const SizedBox(height: 12),
                  _field(_areaCtrl, 'Area Detail (opsional)', Icons.room,
                      hint: 'cth: Pintu depan'),
                  const SizedBox(height: 12),
                  _field(_ipCtrl, 'IP Address', Icons.language,
                      required: true, hint: '192.168.1.100'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _streamType,
                    decoration: _dec(Icons.stream, label: 'Stream Type'),
                    items: const [
                      DropdownMenuItem(value: 'rtsp', child: Text('RTSP')),
                      DropdownMenuItem(value: 'http', child: Text('HTTP')),
                      DropdownMenuItem(value: 'hls', child: Text('HLS')),
                      DropdownMenuItem(value: 'm3u8', child: Text('M3U8')),
                    ],
                    onChanged: (v) =>
                        setState(() => _streamType = v ?? 'rtsp'),
                  ),
                  const SizedBox(height: 12),
                  _field(_urlCtrl, 'Stream URL', Icons.link,
                      required: true,
                      hint: 'rtsp://192.168.1.100:554/stream'),
                  const SizedBox(height: 12),
                  _field(_userCtrl, 'Username (opsional)', Icons.person),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPassword,
                    decoration: _dec(Icons.lock,
                        label: 'Password (opsional)',
                        suffix: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        )),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Aktif'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
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
                    label: Text(_saving ? 'Menyimpan…' : 'Simpan'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {String? hint, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(icon, label: label, hint: hint),
      validator: required
          ? (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null
          : null,
    );
  }

  InputDecoration _dec(IconData icon,
          {String? label, String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.backgroundSoft,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}
