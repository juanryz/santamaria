import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// v1.39 — SO kelola membership consumer (subscription bulanan).
class MembershipListScreen extends StatefulWidget {
  const MembershipListScreen({super.key});

  @override
  State<MembershipListScreen> createState() => _MembershipListScreenState();
}

class _MembershipListScreenState extends State<MembershipListScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _memberships = [];
  String _filter = 'active';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/so/memberships', queryParameters: {
        if (_filter != 'all') 'status': _filter,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() => _memberships =
            List<dynamic>.from(data is Map ? (data['data'] ?? []) : data));
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat daftar membership.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegisterForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _RegisterForm()),
    );
    if (result == true) _load();
  }

  Future<void> _cancel(Map<String, dynamic> m) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Batalkan Membership?',
      message: 'Membership ${m['membership_number']} akan dibatalkan. Iuran yang sudah dibayar tidak dikembalikan.',
      confirmLabel: 'Batalkan',
    );
    if (!ok) return;

    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Pembatalan'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    try {
      final res = await _api.dio
          .put('/so/memberships/${m['id']}/cancel', data: {'reason': reason});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Membership dibatalkan'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal membatalkan'),
            backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Membership Anggota',
        accentColor: AppColors.roleSO,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: _openRegisterForm,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Daftar Anggota',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nomor/nama/HP...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Semua', 'all'),
                _chip('Aktif', 'active'),
                _chip('Grace', 'grace_period'),
                _chip('Inactive', 'inactive'),
                _chip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _memberships.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppColors.brandPrimary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.brandPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildEmpty() => const EmptyStateWidget(
        icon: Icons.card_membership_outlined,
        title: 'Belum Ada Member',
        subtitle: 'Tekan "Daftar Anggota" untuk menambah member baru.',
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _memberships.length,
        itemBuilder: (c, i) =>
            _card(_memberships[i] as Map<String, dynamic>),
      );

  Widget _card(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>?;
    final status = (m['status'] ?? '').toString();
    final fee = num.tryParse('${m['monthly_fee']}') ?? 0;
    final nextDue = DateTime.tryParse(m['next_payment_due'] ?? '');
    final daysToDue = nextDue != null
        ? DateTime.now().difference(nextDue).inDays
        : null;

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.roleSO.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${m['membership_number']} · ${user?['phone'] ?? '-'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const Divider(height: 14),
          Row(
            children: [
              _metric('Iuran/bln',
                  NumberFormat.currency(
                          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(fee)),
              const SizedBox(width: 12),
              if (nextDue != null)
                _metric(
                  'Jatuh Tempo',
                  DateFormat('d MMM', 'id_ID').format(nextDue) +
                      (daysToDue != null && daysToDue > 0
                          ? ' (telat $daysToDue hari)'
                          : ''),
                  color: daysToDue != null && daysToDue > 0
                      ? AppColors.statusDanger
                      : AppColors.textPrimary,
                ),
            ],
          ),
          if (status != 'cancelled') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancel(m),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Batalkan'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusDanger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {Color? color}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textPrimary)),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'active' => ('Aktif', AppColors.statusSuccess),
      'grace_period' => ('Grace', AppColors.statusWarning),
      'inactive' => ('Inactive', AppColors.textHint),
      'cancelled' => ('Cancelled', AppColors.statusDanger),
      'suspended' => ('Suspended', AppColors.statusDanger),
      _ => (status, AppColors.textHint),
    };
    return GlassStatusBadge(label: label, color: color);
  }

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
// Register form — pilih consumer + set fee
// ─────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Map<String, dynamic>> _consumers = [];
  Map<String, dynamic>? _selected;
  bool _searching = false;
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchConsumers(String q) async {
    if (q.trim().length < 2) return;
    setState(() => _searching = true);
    try {
      final res = await _api.dio.get('/admin/users', queryParameters: {
        'role': 'consumer',
        'search': q.trim(),
      });
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final list = data is Map ? (data['data'] ?? []) : data;
        setState(() => _consumers = List<Map<String, dynamic>>.from(list));
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih consumer dulu'),
            backgroundColor: AppColors.statusWarning),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.dio.post('/so/memberships', data: {
        'user_id': _selected!['id'],
        'monthly_fee': num.tryParse(_feeCtrl.text) ?? 0,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Membership ${res.data['data']['membership_number']} dibuat'),
              backgroundColor: AppColors.statusSuccess),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.data['message'] ?? 'Gagal mendaftar'),
              backgroundColor: AppColors.statusDanger),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal mendaftar membership'),
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
      appBar: const GlassAppBar(
        title: 'Daftarkan Anggota',
        accentColor: AppColors.roleSO,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('1. Cari Consumer',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama / HP consumer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => _searchConsumers(v),
            ),
            if (_consumers.isNotEmpty && _selected == null) ...[
              const SizedBox(height: 8),
              ..._consumers.take(8).map((c) => ListTile(
                    title: Text(c['name'] ?? '-'),
                    subtitle: Text(c['phone'] ?? '-'),
                    onTap: () => setState(() {
                      _selected = c;
                      _consumers = [];
                      _searchCtrl.text = c['name'] ?? '';
                    }),
                  )),
            ],
            if (_selected != null) ...[
              const SizedBox(height: 10),
              GlassWidget(
                padding: const EdgeInsets.all(12),
                tint: AppColors.statusSuccess.withOpacity(0.1),
                borderColor: AppColors.statusSuccess.withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.statusSuccess),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!['name'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text(_selected!['phone'] ?? '-',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _selected = null;
                        _searchCtrl.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('2. Iuran Bulanan',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'cth: 50000',
                prefixIcon: const Icon(Icons.payments, size: 20),
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n < 0) return 'Masukkan nominal iuran';
                return null;
              },
            ),

            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)',
                filled: true,
                fillColor: AppColors.backgroundSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),
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
              label: Text(_saving ? 'Menyimpan…' : 'Daftarkan'),
            ),
          ],
        ),
      ),
    );
  }
}
