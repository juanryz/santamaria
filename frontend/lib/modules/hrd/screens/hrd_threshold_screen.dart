import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class HrdThresholdScreen extends StatefulWidget {
  const HrdThresholdScreen({super.key});

  @override
  State<HrdThresholdScreen> createState() => _HrdThresholdScreenState();
}

class _HrdThresholdScreenState extends State<HrdThresholdScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _thresholds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/thresholds');
      if (res.data['success'] == true) {
        _thresholds = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _editThreshold(dynamic threshold) async {
    final controller = TextEditingController(text: threshold['value']?.toString() ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(threshold['description'] ?? threshold['key']),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Nilai (${threshold['key']})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Simpan')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _api.dio.put('/hrd/thresholds/${threshold['key']}', data: {'value': result});
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Threshold diperbarui')));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(title: 'Pengaturan Threshold', accentColor: AppColors.roleHrd),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _thresholds.length,
              itemBuilder: (_, i) {
                final t = _thresholds[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassWidget(
                    borderRadius: 14,
                    child: ListTile(
                      title: Text(t['description'] ?? t['key'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Key: ${t['key']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t['value']?.toString() ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.roleHrd)),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 18),
                        ],
                      ),
                      onTap: () => _editThreshold(t),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
