import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_status_badge.dart';

class SecurityKeyScreen extends StatefulWidget {
  const SecurityKeyScreen({super.key});

  @override
  State<SecurityKeyScreen> createState() => _SecurityKeyScreenState();
}

class _SecurityKeyScreenState extends State<SecurityKeyScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = Color(0xFF636E72);
  bool _isLoading = true;
  List<dynamic> _keys = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/security/keys');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _keys = List<dynamic>.from(data is Map ? data['data'] ?? [] : data ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isOverdue(dynamic key) {
    final expected = key['expected_return_at'];
    if (expected == null) return false;
    try {
      return DateTime.parse(expected).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _returnKey(String id) async {
    try {
      await _api.dio.put('/security/keys/$id/return');
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunci diterima kembali')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _showHandoverForm() {
    final keyLabelCtrl = TextEditingController();
    final handedToCtrl = TextEditingController();
    String keyType = 'vehicle';
    DateTime? expectedReturn;

    const keyTypeOptions = [
      ('vehicle', 'Kendaraan'),
      ('gudang', 'Gudang'),
      ('kantor', 'Kantor'),
      ('ruangan', 'Ruangan'),
      ('other', 'Lainnya'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.fromLTRB(8, 60, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Serahkan Kunci', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: keyType,
                    decoration: const InputDecoration(labelText: 'Jenis Kunci'),
                    items: keyTypeOptions.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                    onChanged: (v) => setSheetState(() => keyType = v ?? 'vehicle'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: keyLabelCtrl, decoration: const InputDecoration(labelText: 'Label Kunci *', hintText: 'Contoh: Kunci Mobil H-1234-AB')),
                  const SizedBox(height: 12),
                  TextField(controller: handedToCtrl, decoration: const InputDecoration(labelText: 'Diserahkan Kepada *', hintText: 'Nama penerima')),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(expectedReturn == null
                        ? 'Perkiraan Kembali (opsional)'
                        : 'Kembali: ${expectedReturn!.day}/${expectedReturn!.month}/${expectedReturn!.year} ${expectedReturn!.hour}:${expectedReturn!.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final date = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                      if (date != null && ctx.mounted) {
                        final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                        if (time != null) {
                          setSheetState(() => expectedReturn = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _roleColor),
                      onPressed: () async {
                        if (keyLabelCtrl.text.isEmpty || handedToCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Label dan penerima wajib diisi')));
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _api.dio.post('/security/keys/handover', data: {
                            'key_type': keyType,
                            'key_label': keyLabelCtrl.text,
                            'handed_to_name': handedToCtrl.text,
                            if (expectedReturn != null) 'expected_return_at': expectedReturn!.toIso8601String(),
                          });
                          _loadData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunci diserahkan')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      },
                      child: const Text('Serahkan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Serah Terima Kunci', accentColor: _roleColor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _roleColor,
        onPressed: _showHandoverForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _keys.isEmpty
                ? ListView(children: const [SizedBox(height: 200), Center(child: Text('Semua kunci sudah kembali'))])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _keys.length,
                    itemBuilder: (_, i) {
                      final k = _keys[i];
                      final overdue = _isOverdue(k);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassWidget(
                          borderRadius: 14,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key, color: overdue ? AppColors.statusDanger : _roleColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(k['key_label'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    if (overdue) const GlassStatusBadge(label: 'OVERDUE', color: AppColors.statusDanger),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Penerima: ${k['handed_to_name'] ?? k['handed_to']?['name'] ?? '-'}', style: const TextStyle(fontSize: 13)),
                                Text('Diserahkan: ${k['handed_at'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (k['expected_return_at'] != null)
                                  Text('Kembali: ${k['expected_return_at']}', style: TextStyle(fontSize: 12, color: overdue ? AppColors.statusDanger : Colors.grey)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _returnKey(k['id']),
                                    icon: const Icon(Icons.keyboard_return, size: 16),
                                    label: const Text('Terima Kembali'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
