import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_widget.dart';

/// v1.36 — Screen Perintah untuk Karyawan
/// Menampilkan perintah yang belum di-acknowledge dan riwayat semua perintah.
/// Dapat diakses dari menu dashboard setiap karyawan.
class EmployeeCommandScreen extends StatefulWidget {
  final Color roleColor;
  const EmployeeCommandScreen({super.key, this.roleColor = AppColors.brandPrimary});

  @override
  State<EmployeeCommandScreen> createState() => _EmployeeCommandScreenState();
}

class _EmployeeCommandScreenState extends State<EmployeeCommandScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabCtrl;

  List<dynamic> _pending  = [];
  List<dynamic> _history  = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.dio.get('/commands/my'),
        _api.dio.get('/commands/history'),
      ]);
      _pending = List<dynamic>.from(results[0].data['data'] ?? []);
      _history = List<dynamic>.from(results[1].data['data']['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acknowledge(String commandId, {String? note}) async {
    try {
      await _api.dio.post('/commands/$commandId/acknowledge',
          data: {'note': note});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perintah dikonfirmasi.'), backgroundColor: Colors.green),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengkonfirmasi.')),
      );
    }
  }

  void _showAcknowledgeDialog(String commandId, String title) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Perintah'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi bahwa Anda telah menerima perintah:\n"$title"',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'misal: Sedang dalam perjalanan...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acknowledge(commandId, note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Siap Laksanakan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Perintah dari Owner',
        accentColor: widget.roleColor,
        showBack: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: widget.roleColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: widget.roleColor,
          tabs: [
            Tab(text: 'Perlu Konfirmasi${_pending.isNotEmpty ? " (${_pending.length})" : ""}'),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _PendingTab(
                  items: _pending,
                  roleColor: widget.roleColor,
                  onAcknowledge: _showAcknowledgeDialog,
                  onRefresh: _load,
                ),
                _HistoryTab(items: _history, onRefresh: _load),
              ],
            ),
    );
  }
}

// ── Tab Perlu Konfirmasi ─────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final List<dynamic> items;
  final Color roleColor;
  final void Function(String commandId, String title) onAcknowledge;
  final VoidCallback onRefresh;

  const _PendingTab({
    required this.items,
    required this.roleColor,
    required this.onAcknowledge,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 12),
          const Text('Tidak ada perintah yang perlu dikonfirmasi.',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item     = items[i];
          final priority = item['priority'] as String? ?? 'normal';
          final title    = item['title'] as String? ?? '-';
          final message  = item['message'] as String? ?? '';
          final owner    = item['owner_name'] as String? ?? 'Owner';
          final commandId = item['command_id'] as String? ?? '';

          final (color, icon) = switch (priority) {
            'urgent' => (const Color(0xFFD32F2F), Icons.warning_rounded),
            'high'   => (const Color(0xFFF57C00), Icons.priority_high),
            _        => (const Color(0xFF1F3D7A), Icons.campaign),
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassWidget(
              borderRadius: 14,
              child: Column(
                children: [
                  // Header berwarna sesuai priority
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
                    ),
                    child: Row(children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(title,
                          style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(priority.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message, style: const TextStyle(fontSize: 13, height: 1.5)),
                        const SizedBox(height: 8),
                        Text('— $owner', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: commandId.isNotEmpty
                                ? () => onAcknowledge(commandId, title)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Siap Laksanakan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tab Riwayat ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<dynamic> items;
  final VoidCallback onRefresh;

  const _HistoryTab({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada riwayat perintah.', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item    = items[i];
          final cmd     = item['command'] as Map<String, dynamic>? ?? {};
          final acked   = item['acknowledged_at'] != null;
          final ackedAt = item['acknowledged_at'] as String?;
          final note    = item['note'] as String?;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassWidget(
              borderRadius: 12,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (acked ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                  child: Icon(
                    acked ? Icons.check_circle : Icons.pending,
                    color: acked ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(cmd['title'] as String? ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cmd['owner']?['name'] as String? ?? 'Owner',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (acked && ackedAt != null)
                      Text('Dikonfirmasi: ${_fmt(ackedAt)}',
                          style: const TextStyle(fontSize: 11, color: Colors.green)),
                    if (note != null && note.isNotEmpty)
                      Text('Catatan: $note',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: Text(
                  (cmd['priority'] as String? ?? '').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: (cmd['priority'] == 'urgent')
                        ? Colors.red
                        : (cmd['priority'] == 'high' ? Colors.orange : Colors.blueGrey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}
