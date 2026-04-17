import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class HrdSalaryConfigScreen extends StatefulWidget {
  const HrdSalaryConfigScreen({super.key});

  @override
  State<HrdSalaryConfigScreen> createState() => _HrdSalaryConfigScreenState();
}

class _HrdSalaryConfigScreenState extends State<HrdSalaryConfigScreen> {
  final ApiClient _api = ApiClient();
  static const _roleColor = AppColors.roleHrd;

  bool _isLoading = true;
  List<dynamic> _configs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hrd/salaries');
      if (res.data['success'] == true) {
        _configs = List<dynamic>.from(res.data['data'] ?? []);
      }
    } catch (_) {
      _configs = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is num) ? amount.toInt() : int.tryParse('$amount') ?? 0;
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _showForm({dynamic existing}) {
    final nameCtrl = TextEditingController(text: existing?['employee_name'] ?? '');
    final salaryCtrl = TextEditingController(text: '${existing?['base_salary'] ?? ''}');
    String type = existing?['type'] ?? 'fixed';
    String effectiveDate = existing?['effective_date'] ?? DateTime.now().toString().substring(0, 10);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(existing != null ? 'Edit Konfigurasi Gaji' : 'Tambah Konfigurasi Gaji', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (existing == null)
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Karyawan / ID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (existing == null) const SizedBox(height: 12),
                TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Gaji Pokok (Rp)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tipe Gaji', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fixed', style: TextStyle(fontSize: 13)),
                        value: 'fixed',
                        groupValue: type,
                        onChanged: (v) => setSheetState(() => type = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Performance', style: TextStyle(fontSize: 13)),
                        value: 'performance_based',
                        groupValue: type,
                        onChanged: (v) => setSheetState(() => type = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.tryParse(effectiveDate) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setSheetState(() => effectiveDate = picked.toString().substring(0, 10));
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Berlaku Sejak',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(effectiveDate),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final data = {
                          'base_salary': int.tryParse(salaryCtrl.text) ?? 0,
                          'type': type,
                          'effective_date': effectiveDate,
                        };
                        if (existing != null) {
                          await _api.dio.put('/hrd/salaries/${existing['id']}', data: data);
                        } else {
                          data['employee_identifier'] = nameCtrl.text;
                          await _api.dio.post('/hrd/salaries', data: data);
                        }
                        await _load();
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan.')));
                        }
                      }
                    },
                    child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
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
      appBar: GlassAppBar(title: 'Konfigurasi Gaji', accentColor: _roleColor, showBack: true),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _roleColor,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _configs.isEmpty
                  ? ListView(children: const [SizedBox(height: 200), Center(child: Text('Belum ada konfigurasi gaji.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _configs.length,
                      itemBuilder: (_, i) {
                        final c = _configs[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassWidget(
                            borderRadius: 14,
                            onTap: () => _showForm(existing: c),
                            child: ListTile(
                              title: Text(c['employee_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('${c['role'] ?? '-'} | ${c['type'] ?? 'fixed'} | Berlaku: ${c['effective_date'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                              trailing: Text(_formatCurrency(c['base_salary']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
