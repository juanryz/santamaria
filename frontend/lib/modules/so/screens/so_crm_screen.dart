import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';

class SoCrmScreen extends StatefulWidget {
  const SoCrmScreen({super.key});

  @override
  State<SoCrmScreen> createState() => _SoCrmScreenState();
}

class _SoCrmScreenState extends State<SoCrmScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ApiClient _api;

  List<dynamic> _prospects = [];
  List<dynamic> _visits = [];
  Map<String, dynamic>? _dailyReport;
  bool _loadingProspects = true;
  bool _loadingVisits = true;

  static const _roleColor = AppColors.roleSO;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _api = ApiClient();
    _loadProspects();
    _loadVisits();
    _loadDailyReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProspects() async {
    setState(() => _loadingProspects = true);
    try {
      final res = await _api.dio.get('/so/prospects');
      if (res.data['success'] == true) {
        final paginated = res.data['data'];
        setState(() => _prospects = (paginated['data'] ?? paginated) as List);
      }
    } catch (_) {}
    setState(() => _loadingProspects = false);
  }

  Future<void> _loadVisits() async {
    setState(() => _loadingVisits = true);
    try {
      final res = await _api.dio.get('/so/visits');
      if (res.data['success'] == true) {
        final paginated = res.data['data'];
        setState(() => _visits = (paginated['data'] ?? paginated) as List);
      }
    } catch (_) {}
    setState(() => _loadingVisits = false);
  }

  Future<void> _loadDailyReport() async {
    try {
      final res = await _api.dio.get('/so/daily-report');
      if (res.data['success'] == true) {
        setState(() => _dailyReport = res.data['data']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CRM', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _roleColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: _roleColor,
          tabs: const [
            Tab(text: 'Prospek'),
            Tab(text: 'Kunjungan'),
            Tab(text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProspectTab(),
          _buildVisitTab(),
          _buildReportTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _roleColor,
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddProspectDialog();
          } else if (_tabController.index == 1) {
            _showAddVisitDialog();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Prospect Tab ─────────────────────────────────────────────

  Widget _buildProspectTab() {
    if (_loadingProspects) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prospects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Belum ada prospek.', style: TextStyle(color: AppColors.textSecondary)),
            Text('Tap + untuk menambah prospek baru.', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadProspects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prospects.length,
        itemBuilder: (_, i) => _buildProspectCard(_prospects[i]),
      ),
    );
  }

  Widget _buildProspectCard(Map<String, dynamic> p) {
    final status = p['status'] ?? 'new';
    final statusColor = _prospectStatusColor(status);
    final followUp = p['follow_up_date'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p['name'] ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (p['phone'] != null) ...[
              const SizedBox(height: 4),
              Text(p['phone'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
            if (p['source'] != null) ...[
              const SizedBox(height: 4),
              Text('Sumber: ${p['source']}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
            if (followUp != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.statusWarning),
                  const SizedBox(width: 4),
                  Text('Follow-up: $followUp',
                      style: const TextStyle(color: AppColors.statusWarning, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _prospectStatusColor(String s) {
    return switch (s) {
      'new' => AppColors.statusInfo,
      'contacted' => AppColors.statusWarning,
      'interested' => AppColors.brandSecondary,
      'converted' => AppColors.statusSuccess,
      'lost' => AppColors.textHint,
      _ => AppColors.textSecondary,
    };
  }

  // ── Visit Tab ────────────────────────────────────────────────

  Widget _buildVisitTab() {
    if (_loadingVisits) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_visits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Belum ada kunjungan.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVisits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length,
        itemBuilder: (_, i) => _buildVisitCard(_visits[i]),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> v) {
    final prospect = v['prospect'] as Map<String, dynamic>?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.roleSO),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(v['location'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                ),
                Text(v['visit_date'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(v['purpose'] ?? '-',
                  style: TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            if (prospect != null) ...[
              const SizedBox(height: 6),
              Text('Prospek: ${prospect['name']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
            if (v['notes'] != null && (v['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(v['notes'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  // ── Daily Report Tab ─────────────────────────────────────────

  Widget _buildReportTab() {
    if (_dailyReport == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final r = _dailyReport!;
    final followUps = (r['follow_ups_today'] ?? []) as List;

    return RefreshIndicator(
      onRefresh: _loadDailyReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Laporan Hari Ini', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(r['date'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Order Dibuat', '${r['orders_created'] ?? 0}', Icons.shopping_cart, AppColors.statusInfo),
              const SizedBox(width: 12),
              _statCard('Kunjungan', '${r['visits_done'] ?? 0}', Icons.directions_walk, AppColors.brandSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Prospek Baru', '${r['prospects_added'] ?? 0}', Icons.person_add, AppColors.statusWarning),
              const SizedBox(width: 12),
              _statCard('Total Aktivitas', '${r['total_activities'] ?? 0}', Icons.bar_chart, _roleColor),
            ],
          ),
          if (followUps.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Follow-up Hari Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...followUps.map((fu) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassWidget(
                borderRadius: 12,
                blurSigma: 10,
                tint: AppColors.glassWhite,
                borderColor: AppColors.statusWarning.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, size: 16, color: AppColors.statusWarning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fu['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (fu['phone'] != null)
                            Text(fu['phone'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _prospectStatusColor(fu['status'] ?? 'new').withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text((fu['status'] ?? '').toUpperCase(),
                          style: TextStyle(color: _prospectStatusColor(fu['status'] ?? 'new'), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassWidget(
        borderRadius: 16,
        blurSigma: 12,
        tint: color.withValues(alpha: 0.06),
        borderColor: color.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────

  void _showAddProspectDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String source = 'referral';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Prospek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama *')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. HP / WA'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: source,
                decoration: const InputDecoration(labelText: 'Sumber'),
                items: const [
                  DropdownMenuItem(value: 'referral', child: Text('Referral')),
                  DropdownMenuItem(value: 'walk_in', child: Text('Walk-in')),
                  DropdownMenuItem(value: 'rs', child: Text('Rumah Sakit')),
                  DropdownMenuItem(value: 'online', child: Text('Online')),
                  DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                ],
                onChanged: (v) => source = v ?? 'referral',
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan'), maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _api.dio.post('/so/prospects', data: {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                        'source': source,
                        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      });
                      _loadProspects();
                      _loadDailyReport();
                    } catch (_) {}
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVisitDialog() {
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String purpose = 'prospek';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Kunjungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Lokasi *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: purpose,
                decoration: const InputDecoration(labelText: 'Tujuan'),
                items: const [
                  DropdownMenuItem(value: 'prospek', child: Text('Prospek Baru')),
                  DropdownMenuItem(value: 'follow_up', child: Text('Follow Up')),
                  DropdownMenuItem(value: 'order_coordination', child: Text('Koordinasi Order')),
                  DropdownMenuItem(value: 'rumah_duka_visit', child: Text('Kunjungan Rumah Duka')),
                ],
                onChanged: (v) => purpose = v ?? 'prospek',
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Catatan'), maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _roleColor),
                  onPressed: () async {
                    if (locationCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _api.dio.post('/so/visits', data: {
                        'location': locationCtrl.text.trim(),
                        'purpose': purpose,
                        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        'visit_date': DateTime.now().toIso8601String().split('T')[0],
                      });
                      _loadVisits();
                      _loadDailyReport();
                    } catch (_) {}
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
