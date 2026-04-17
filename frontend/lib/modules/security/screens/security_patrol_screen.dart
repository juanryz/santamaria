import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class SecurityPatrolScreen extends StatefulWidget {
  const SecurityPatrolScreen({super.key});

  @override
  State<SecurityPatrolScreen> createState() => _SecurityPatrolScreenState();
}

class _SecurityPatrolScreenState extends State<SecurityPatrolScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  static const _roleColor = Color(0xFF636E72);
  late TabController _tabCtrl;

  // Active patrol state
  bool _isPatrolling = false;
  DateTime? _patrolStart;
  List<dynamic> _checkpoints = [];
  // checkpoint_id -> { checked: bool, status: 'ok'|'issue', notes: String?, photoPath: String? }
  final Map<String, Map<String, dynamic>> _checkResults = {};

  // History
  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCheckpoints();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCheckpoints() async {
    try {
      final res = await _api.dio.get('/security/patrols/schedule');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _checkpoints = List<dynamic>.from(data is Map ? data['checkpoints'] ?? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {
      // Fallback: use some default checkpoints if API not ready
      _checkpoints = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final res = await _api.dio.get('/security/patrols');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _history = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  void _startPatrol() {
    setState(() {
      _isPatrolling = true;
      _patrolStart = DateTime.now();
      _checkResults.clear();
    });
  }

  String _elapsed() {
    if (_patrolStart == null) return '00:00';
    final diff = DateTime.now().difference(_patrolStart!);
    final m = diff.inMinutes.toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _checkOk(String checkpointId) async {
    setState(() {
      _checkResults[checkpointId] = {'checked': true, 'status': 'ok', 'checked_at': DateTime.now().toIso8601String()};
    });
  }

  Future<void> _reportIssue(String checkpointId, String checkpointName) async {
    final notesCtrl = TextEditingController();
    File? photo;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Masalah: $checkpointName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan masalah *'), maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
                      if (picked != null) setDlgState(() => photo = File(picked.path));
                    },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Foto'),
                  ),
                  if (photo != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _checkResults[checkpointId] = {
          'checked': true,
          'status': 'issue',
          'notes': notesCtrl.text,
          'photo_path': photo?.path,
          'checked_at': DateTime.now().toIso8601String(),
        };
      });
    }
  }

  Future<void> _submitPatrol() async {
    if (_checkResults.length < _checkpoints.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selesaikan semua checkpoint terlebih dahulu')));
      return;
    }

    try {
      final checkpointsPayload = _checkpoints.map((cp) {
        final id = cp['id'] ?? cp['checkpoint_code'] ?? '';
        final result = _checkResults[id] ?? {'status': 'ok', 'checked_at': DateTime.now().toIso8601String()};
        return {
          'checkpoint_id': id,
          'checked_at': result['checked_at'],
          'status': result['status'],
          'notes': result['notes'],
        };
      }).toList();

      // Upload photos separately if needed
      final hasIssues = _checkResults.values.any((r) => r['status'] == 'issue');

      await _api.dio.post('/security/patrols', data: {
        'started_at': _patrolStart!.toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'checkpoints': checkpointsPayload,
        'all_clear': !hasIssues,
      });

      setState(() {
        _isPatrolling = false;
        _patrolStart = null;
        _checkResults.clear();
      });
      _loadHistory();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patroli selesai')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Patroli', accentColor: _roleColor),
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelColor: _roleColor,
            indicatorColor: _roleColor,
            tabs: const [Tab(text: 'Patroli'), Tab(text: 'Riwayat')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_patrolTab(), _historyTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patrolTab() {
    if (!_isPatrolling) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 64, color: _roleColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('${_checkpoints.length} checkpoint siap', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _roleColor, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              onPressed: _checkpoints.isEmpty ? null : _startPatrol,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Patroli'),
            ),
          ],
        ),
      );
    }

    final checkedCount = _checkResults.values.where((r) => r['checked'] == true).length;

    return Column(
      children: [
        // Timer + progress
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassWidget(
            borderRadius: 14,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: _roleColor, size: 24),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    builder: (_, _, _) => Text(_elapsed(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text('$checkedCount / ${_checkpoints.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: _checkpoints.isEmpty ? 0 : checkedCount / _checkpoints.length,
                      backgroundColor: Colors.grey[200],
                      color: _roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Checkpoints list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _checkpoints.length,
            itemBuilder: (_, i) {
              final cp = _checkpoints[i];
              final id = cp['id'] ?? cp['checkpoint_code'] ?? '$i';
              final name = cp['checkpoint_name'] ?? cp['name'] ?? 'Checkpoint ${i + 1}';
              final result = _checkResults[id];
              final isChecked = result?['checked'] == true;
              final isIssue = result?['status'] == 'issue';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassWidget(
                  borderRadius: 14,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          isChecked ? (isIssue ? Icons.warning : Icons.check_circle) : Icons.radio_button_unchecked,
                          color: isChecked ? (isIssue ? Colors.orange : Colors.green) : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (isIssue && result?['notes'] != null)
                                Text(result!['notes'], style: const TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                        ),
                        if (!isChecked) ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'OK',
                            onPressed: () => _checkOk(id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.warning_amber, color: Colors.orange),
                            tooltip: 'Masalah',
                            onPressed: () => _reportIssue(id, name),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Submit
        if (checkedCount == _checkpoints.length && _checkpoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _roleColor),
                onPressed: _submitPatrol,
                child: const Text('Selesai Patroli'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyTab() {
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) return const Center(child: Text('Belum ada riwayat patroli'));

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final p = _history[i];
          final allClear = p['all_clear'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassWidget(
              borderRadius: 14,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(allClear ? Icons.check_circle : Icons.warning, color: allClear ? Colors.green : Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['started_at'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(allClear ? 'Semua aman' : 'Ada masalah ditemukan', style: TextStyle(fontSize: 12, color: allClear ? Colors.green : Colors.orange)),
                        ],
                      ),
                    ),
                    GlassStatusBadge(label: allClear ? 'CLEAR' : 'ISSUE', color: allClear ? Colors.green : Colors.orange),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
