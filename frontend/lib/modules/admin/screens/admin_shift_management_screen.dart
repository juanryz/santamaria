import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';

class AdminShiftManagementScreen extends StatefulWidget {
  final String orderId;
  final String orderCode;

  const AdminShiftManagementScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<AdminShiftManagementScreen> createState() =>
      _AdminShiftManagementScreenState();
}

class _AdminShiftManagementScreenState extends State<AdminShiftManagementScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabCtrl;

  // Tab 1
  bool _loadingShifts = true;
  List<dynamic> _shifts = [];
  String? _shiftsError;

  // Tab 2
  bool _loadingWageConfigs = true;
  List<dynamic> _wageConfigs = [];
  String? _wageError;

  // For assign dropdown
  List<dynamic> _tukangJagaUsers = [];

  static const _roleColor = AppColors.roleAdmin;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadShifts();
    _loadWageConfigs();
    _loadTukangJagaUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    setState(() {
      _loadingShifts = true;
      _shiftsError = null;
    });
    try {
      final res =
          await _api.dio.get('/admin/orders/${widget.orderId}/shifts');
      if (res.data['success'] == true) {
        setState(() => _shifts = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(
            () => _shiftsError = res.data['message'] ?? 'Gagal memuat shift.');
      }
    } catch (_) {
      setState(() => _shiftsError = 'Gagal memuat shift.');
    } finally {
      if (mounted) setState(() => _loadingShifts = false);
    }
  }

  Future<void> _loadWageConfigs() async {
    setState(() {
      _loadingWageConfigs = true;
      _wageError = null;
    });
    try {
      final res = await _api.dio.get('/admin/tukang-jaga/wage-configs');
      if (res.data['success'] == true) {
        setState(
            () => _wageConfigs = List<dynamic>.from(res.data['data'] ?? []));
      } else {
        setState(() =>
            _wageError = res.data['message'] ?? 'Gagal memuat konfigurasi.');
      }
    } catch (_) {
      setState(() => _wageError = 'Gagal memuat konfigurasi upah.');
    } finally {
      if (mounted) setState(() => _loadingWageConfigs = false);
    }
  }

  Future<void> _loadTukangJagaUsers() async {
    try {
      final res =
          await _api.dio.get('/admin/users', queryParameters: {'role': 'tukang_jaga'});
      if (res.data['success'] == true) {
        setState(() =>
            _tukangJagaUsers = List<dynamic>.from(res.data['data'] ?? []));
      }
    } catch (_) {}
  }

  Color _shiftTypeColor(String? type) => switch (type) {
        'pagi' => Colors.orange,
        'siang' => Colors.blue,
        'malam' => Colors.purple,
        'full_day' => Colors.teal,
        _ => AppColors.brandSecondary,
      };

  Color _statusColor(String? status) => switch (status) {
        'scheduled' => Colors.grey,
        'active' => Colors.green.shade600,
        'completed' => Colors.blue,
        'missed' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String _statusLabel(String? status) => switch (status) {
        'scheduled' => 'Terjadwal',
        'active' => 'Aktif',
        'completed' => 'Selesai',
        'missed' => 'Terlewat',
        _ => status ?? '-',
      };

  String _formatDateTime(String? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  String _formatCurrency(dynamic amount) {
    final num = double.tryParse(amount?.toString() ?? '') ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(num);
  }

  void _showGenerateShiftSheet() {
    final daysCtrl = TextEditingController(text: '3');
    final spd = TextEditingController(text: '2');
    String? selectedWageConfig;
    final selectedTypes = <String>{};
    final shiftTypes = ['pagi', 'siang', 'malam', 'full_day'];
    bool generating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Generate Shift',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: daysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Jumlah Hari'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: spd,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Shift/Hari'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tipe Shift',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: shiftTypes.map((t) {
                    final selected = selectedTypes.contains(t);
                    final c = _shiftTypeColor(t);
                    return FilterChip(
                      label: Text(t.toUpperCase()),
                      selected: selected,
                      selectedColor: c.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                          color: selected ? c : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      onSelected: (v) => setLocal(() {
                        if (v) {
                          selectedTypes.add(t);
                        } else {
                          selectedTypes.remove(t);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Konfigurasi Upah',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedWageConfig,
                  hint: const Text('Pilih konfigurasi upah',
                      style: TextStyle(color: AppColors.textHint)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.glassWhite,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                  ),
                  items: _wageConfigs.map((wc) {
                    return DropdownMenuItem<String>(
                      value: wc['id'].toString(),
                      child: Text(
                          '${wc['label'] ?? '-'} (${_formatCurrency(wc['rate'])})'),
                    );
                  }).toList(),
                  onChanged: (v) => setLocal(() => selectedWageConfig = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: generating
                        ? null
                        : () async {
                            if (selectedTypes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Pilih minimal satu tipe shift.')),
                              );
                              return;
                            }
                            setLocal(() => generating = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final res = await _api.dio.post(
                                '/admin/orders/${widget.orderId}/shifts/generate',
                                data: {
                                  'days': int.tryParse(daysCtrl.text) ?? 1,
                                  'shifts_per_day':
                                      int.tryParse(spd.text) ?? 2,
                                  'shift_types': selectedTypes.toList(),
                                  'wage_config_id': selectedWageConfig,
                                },
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              if (res.data['success'] == true) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Shift berhasil di-generate!'),
                                      backgroundColor: AppColors.statusSuccess),
                                );
                                _loadShifts();
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                      content: Text(res.data['message'] ??
                                          'Gagal generate shift.')),
                                );
                              }
                            } catch (_) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Gagal generate shift.')),
                                );
                              }
                            } finally {
                              if (mounted) setLocal(() => generating = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: generating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Generate Shift',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignSheet(Map<String, dynamic> shift) {
    String? selectedUserId;
    bool assigning = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Tukang Jaga — Shift ${shift['shift_number'] ?? '-'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  hint: const Text('Pilih Tukang Jaga',
                      style: TextStyle(color: AppColors.textHint)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.glassWhite,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                  ),
                  items: _tukangJagaUsers.map((u) {
                    return DropdownMenuItem<String>(
                      value: u['id'].toString(),
                      child: Text(u['name'] ?? '-'),
                    );
                  }).toList(),
                  onChanged: (v) => setLocal(() => selectedUserId = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (assigning || selectedUserId == null)
                        ? null
                        : () async {
                            setLocal(() => assigning = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final res = await _api.dio.put(
                                '/admin/shifts/${shift['id']}/assign',
                                data: {'user_id': selectedUserId},
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              if (res.data['success'] == true) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Tukang jaga berhasil di-assign!'),
                                      backgroundColor: AppColors.statusSuccess),
                                );
                                _loadShifts();
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                      content: Text(res.data['message'] ??
                                          'Gagal assign.')),
                                );
                              }
                            } catch (_) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Gagal assign tukang jaga.')),
                                );
                              }
                            } finally {
                              if (mounted) setLocal(() => assigning = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: assigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Assign',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWageConfigDialog() {
    final labelCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    String? selectedType;
    final shiftTypes = ['pagi', 'siang', 'malam', 'full_day'];
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah Konfigurasi Upah'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: _inputDecoration('Label (contoh: Shift Pagi Standar)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  hint: const Text('Tipe Shift',
                      style: TextStyle(color: AppColors.textHint)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.glassWhite,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.glassBorder)),
                  ),
                  items: shiftTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedType = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Rate (Rp)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (labelCtrl.text.trim().isEmpty ||
                          selectedType == null ||
                          rateCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Semua field wajib diisi.')),
                        );
                        return;
                      }
                      setLocal(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final res = await _api.dio.post(
                          '/admin/tukang-jaga/wage-configs',
                          data: {
                            'label': labelCtrl.text.trim(),
                            'shift_type': selectedType,
                            'rate': double.tryParse(rateCtrl.text.trim()) ?? 0,
                          },
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        if (res.data['success'] == true) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('Konfigurasi upah ditambahkan!'),
                                backgroundColor: AppColors.statusSuccess),
                          );
                          _loadWageConfigs();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(res.data['message'] ??
                                    'Gagal menyimpan.')),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('Gagal menyimpan konfigurasi.')),
                          );
                        }
                      } finally {
                        if (mounted) setLocal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.glassWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Shift — ${widget.orderCode}',
        accentColor: _roleColor,
        showBack: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _roleColor,
          labelColor: _roleColor,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Daftar Shift'),
            Tab(text: 'Konfigurasi Upah'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, _) {
          if (_tabCtrl.index == 0) {
            return FloatingActionButton.extended(
              heroTag: 'generate_shift',
              backgroundColor: _roleColor,
              onPressed: _showGenerateShiftSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Generate Shift',
                  style: TextStyle(color: Colors.white)),
            );
          } else {
            return FloatingActionButton.extended(
              heroTag: 'add_wage',
              backgroundColor: _roleColor,
              onPressed: _showAddWageConfigDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Konfigurasi',
                  style: TextStyle(color: Colors.white)),
            );
          }
        },
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildShiftsTab(),
          _buildWageConfigTab(),
        ],
      ),
    );
  }

  Widget _buildShiftsTab() {
    if (_loadingShifts) return const Center(child: CircularProgressIndicator());
    if (_shiftsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusDanger, size: 48),
              const SizedBox(height: 16),
              Text(_shiftsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadShifts,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShifts,
      child: _shifts.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(
                child: Column(children: [
                  Icon(Icons.event_note, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Belum ada shift. Tekan "Generate Shift".',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _shifts.length,
              itemBuilder: (_, i) => _buildShiftCard(_shifts[i]),
            ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final status = shift['status'] as String?;
    final shiftType = shift['shift_type'] as String?;
    final sc = _statusColor(status);
    final tc = _shiftTypeColor(shiftType);
    final assignedTo = shift['assigned_to'] as Map<String, dynamic>?;
    final wageFmt = shift['wage_amount'] != null
        ? _formatCurrency(shift['wage_amount'])
        : '-';

    return GestureDetector(
      onLongPress: () => _showAssignSheet(shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassWidget(
          borderRadius: 18,
          blurSigma: 14,
          tint: AppColors.glassWhite,
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Shift ${shift['shift_number'] ?? '-'}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tc.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(shiftType?.toUpperCase() ?? '-',
                        style: TextStyle(
                            color: tc,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(status),
                        style: TextStyle(
                            color: sc,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_formatDateTime(shift['scheduled_start'])} → ${_formatDateTime(shift['scheduled_end'])}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    assignedTo?['name'] ?? 'Belum ditugaskan',
                    style: TextStyle(
                        color: assignedTo != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 12,
                        fontStyle: assignedTo == null
                            ? FontStyle.italic
                            : FontStyle.normal),
                  ),
                ],
              ),
              if (shift['wage_amount'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(wageFmt,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Tahan lama untuk assign tukang jaga',
                style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWageConfigTab() {
    if (_loadingWageConfigs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_wageError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusDanger, size: 48),
              const SizedBox(height: 16),
              Text(_wageError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadWageConfigs,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWageConfigs,
      child: _wageConfigs.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(
                child: Column(children: [
                  Icon(Icons.payments_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Belum ada konfigurasi upah.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _wageConfigs.length,
              itemBuilder: (_, i) => _buildWageConfigCard(_wageConfigs[i]),
            ),
    );
  }

  Widget _buildWageConfigCard(Map<String, dynamic> config) {
    final isActive = config['is_active'] == true;
    final shiftType = config['shift_type'] as String?;
    final tc = _shiftTypeColor(shiftType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: tc,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config['label'] ?? '-',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(shiftType?.toUpperCase() ?? '-',
                            style: TextStyle(
                                color: tc,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCurrency(config['rate']),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              activeThumbColor: AppColors.statusSuccess,
              onChanged: (v) => _toggleWageConfig(config['id'].toString(), v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWageConfig(String id, bool active) async {
    try {
      await _api.dio.patch('/admin/tukang-jaga/wage-configs/$id',
          data: {'is_active': active});
      _loadWageConfigs();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah status konfigurasi.')),
        );
      }
    }
  }
}
