import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

/// v1.36 — Owner: Kirim Perintah ke Karyawan
/// Owner memilih target (individu / role), isi judul + pesan, pilih prioritas,
/// lalu kirim. Karyawan menerima alarm paksa di device mereka.
class OwnerCommandScreen extends StatefulWidget {
  const OwnerCommandScreen({super.key});

  @override
  State<OwnerCommandScreen> createState() => _OwnerCommandScreenState();
}

class _OwnerCommandScreenState extends State<OwnerCommandScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  static const _roleColor = AppColors.roleOwner;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _commands = [];
  List<dynamic> _employees = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/owner/commands'),
        _api.dio.get('/hrd/employees'),
        _api.dio.get('/super-admin/roles'),
      ]);
      _commands  = List<dynamic>.from(results[0].data['data']['data'] ?? []);
      _employees = List<dynamic>.from(results[1].data['data']['data'] ?? []);
      final allRoles = (results[2].data['data'] as List).cast<Map<String, dynamic>>();
      _roles = allRoles.where((r) =>
        !['consumer', 'super_admin', 'owner'].contains(r['slug']) &&
        (r['is_active'] as bool? ?? true)
      ).toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Perintah Karyawan',
        accentColor: _roleColor,
        showBack: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _roleColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _roleColor,
          tabs: const [
            Tab(text: 'Riwayat Perintah'),
            Tab(text: 'Kirim Baru'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _CommandHistoryTab(commands: _commands, isLoading: _isLoading, onRefresh: _loadData),
          _SendCommandTab(employees: _employees, roles: _roles, onSent: _loadData),
        ],
      ),
    );
  }
}

// ── Tab Riwayat ──────────────────────────────────────────────────────────────

class _CommandHistoryTab extends StatelessWidget {
  final List<dynamic> commands;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _CommandHistoryTab({required this.commands, required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (commands.isEmpty) {
      return const Center(child: Text('Belum ada perintah dikirim.', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commands.length,
        itemBuilder: (_, i) => _CommandCard(command: commands[i]),
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  final dynamic command;
  const _CommandCard({required this.command});

  static const _priorityColor = {
    'urgent': Color(0xFFD32F2F),
    'high':   Color(0xFFF57C00),
    'normal': Color(0xFF1F3D7A),
  };

  static const _statusLabel = {
    'sent':             'Terkirim',
    'partial':          'Sebagian Diterima',
    'all_acknowledged': 'Semua Dikonfirmasi',
  };

  @override
  Widget build(BuildContext context) {
    final priority    = command['priority'] as String? ?? 'normal';
    final status      = command['status'] as String? ?? 'sent';
    final receipts    = command['receipts_count'] as int? ?? 0;
    final acked       = command['acknowledged_count'] as int? ?? 0;
    final target      = command['target_user']?['name'] as String?
                     ?? (command['target_role'] != null ? 'Role: ${command['target_role']}' : '-');
    final sentAt      = command['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 14,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: (_priorityColor[priority] ?? Colors.grey).withValues(alpha: 0.15),
            child: Icon(
              priority == 'urgent' ? Icons.warning_rounded : Icons.campaign,
              color: _priorityColor[priority] ?? Colors.grey,
              size: 20,
            ),
          ),
          title: Text(command['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ke: $target', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Row(children: [
                _chip(_statusLabel[status] ?? status,
                    status == 'all_acknowledged' ? Colors.green : Colors.orange),
                const SizedBox(width: 6),
                _chip(priority.toUpperCase(), _priorityColor[priority] ?? Colors.grey),
              ]),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(command['message'] ?? '', style: const TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.people, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$acked / $receipts karyawan konfirmasi',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    Text(_formatTime(sentAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    margin: const EdgeInsets.only(top: 4, right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
  );

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}

// ── Tab Kirim Perintah ───────────────────────────────────────────────────────

class _SendCommandTab extends StatefulWidget {
  final List<dynamic> employees;
  final List<Map<String, dynamic>> roles;
  final VoidCallback onSent;

  const _SendCommandTab({required this.employees, required this.roles, required this.onSent});

  @override
  State<_SendCommandTab> createState() => _SendCommandTabState();
}

class _SendCommandTabState extends State<_SendCommandTab> {
  final _api        = ApiClient();
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _msgCtrl    = TextEditingController();

  static const _roleColor = AppColors.roleOwner;

  String _targetType = 'individual'; // 'individual' | 'role'
  String? _selectedUserId;
  String? _selectedRole;
  String _priority = 'normal';
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType == 'individual' && _selectedUserId == null) {
      _snack('Pilih karyawan terlebih dahulu.'); return;
    }
    if (_targetType == 'role' && _selectedRole == null) {
      _snack('Pilih role terlebih dahulu.'); return;
    }

    setState(() => _isSending = true);
    try {
      final data = <String, dynamic>{
        'title':    _titleCtrl.text.trim(),
        'message':  _msgCtrl.text.trim(),
        'priority': _priority,
        if (_targetType == 'individual') 'target_user_id': _selectedUserId,
        if (_targetType == 'role')       'target_role': _selectedRole,
      };
      final res = await _api.dio.post('/owner/commands', data: data);
      final count = res.data['recipients_count'] as int? ?? 0;
      _snack('Perintah terkirim ke $count karyawan. Alarm aktif!', success: true);
      _titleCtrl.clear();
      _msgCtrl.clear();
      setState(() { _selectedUserId = null; _selectedRole = null; _priority = 'normal'; });
      widget.onSent();
    } catch (_) {
      _snack('Gagal mengirim perintah.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Target ──
            _section('Target Penerima'),
            Row(children: [
              _targetChip('Individu', 'individual'),
              const SizedBox(width: 8),
              _targetChip('Semua Role', 'role'),
            ]),
            const SizedBox(height: 12),
            if (_targetType == 'individual')
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Karyawan',
                  prefixIcon: Icon(Icons.person, size: 20, color: AppColors.textHint),
                ),
                items: widget.employees.map((e) => DropdownMenuItem<String>(
                  value: e['id'] as String,
                  child: Text('${e['name']} (${e['role']})', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Pilih Role',
                  prefixIcon: Icon(Icons.group, size: 20, color: AppColors.textHint),
                ),
                items: widget.roles.map((r) => DropdownMenuItem<String>(
                  value: r['slug'] as String,
                  child: Text(r['label'] as String? ?? r['slug'] as String),
                )).toList(),
                onChanged: (v) => setState(() => _selectedRole = v),
              ),

            const SizedBox(height: 20),

            // ── Prioritas ──
            _section('Prioritas'),
            Row(children: [
              _priorityChip('Normal', 'normal', const Color(0xFF1F3D7A)),
              const SizedBox(width: 8),
              _priorityChip('Tinggi', 'high', const Color(0xFFF57C00)),
              const SizedBox(width: 8),
              _priorityChip('Mendesak', 'urgent', const Color(0xFFD32F2F)),
            ]),
            const SizedBox(height: 20),

            // ── Pesan ──
            _section('Pesan'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Perintah *',
                prefixIcon: Icon(Icons.title, size: 20, color: AppColors.textHint),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detail Perintah *',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.notes, size: 20, color: AppColors.textHint),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 8),

            // Warning urgent
            if (_priority == 'urgent')
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Prioritas MENDESAK akan membunyikan alarm keras dan memaksa layar karyawan menyala.',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  )),
                ]),
              ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _priority == 'urgent' ? const Color(0xFFD32F2F) : _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.campaign),
                label: Text(_isSending ? 'Mengirim...' : 'Kirim Perintah & Aktifkan Alarm'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
      style: const TextStyle(color: _roleColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
  );

  Widget _targetChip(String label, String value) {
    final selected = _targetType == value;
    return GestureDetector(
      onTap: () => setState(() { _targetType = value; _selectedUserId = null; _selectedRole = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _roleColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _roleColor : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        )),
      ),
    );
  }

  Widget _priorityChip(String label, String value, Color color) {
    final selected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        )),
      ),
    );
  }
}
