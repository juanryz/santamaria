import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';

/// v1.39 — Petty cash (kas kecil kantor) tracking.
/// Saldo berjalan + in/out + kategori + foto nota.
class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({super.key});

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  num _balance = 0;
  List<dynamic> _transactions = [];
  String _filter = 'all';

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
      final res = await _api.dio.get('/purchasing/petty-cash', queryParameters: {
        if (_filter != 'all') 'direction': _filter,
      });
      if (!mounted) return;
      if (res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _balance = num.tryParse('${d['current_balance']}') ?? 0;
          final txData = d['transactions'];
          _transactions = List<dynamic>.from(
              txData is Map ? (txData['data'] ?? []) : txData);
        });
      } else {
        setState(() => _error = res.data['message'] ?? 'Gagal memuat data.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat kas kecil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    String direction = 'out';
    String? category;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => AlertDialog(
          title: const Text('Catat Transaksi Kas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'in', label: Text('Kas Masuk'), icon: Icon(Icons.add)),
                    ButtonSegment(
                        value: 'out', label: Text('Kas Keluar'), icon: Icon(Icons.remove)),
                  ],
                  selected: {direction},
                  onSelectionChanged: (s) => setLocal(() => direction = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Kategori (opsional)',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('—')),
                    DropdownMenuItem(value: 'operational', child: Text('Operasional')),
                    DropdownMenuItem(value: 'refund', child: Text('Refund')),
                    DropdownMenuItem(value: 'reimbursement', child: Text('Reimbursement')),
                    DropdownMenuItem(value: 'initial_topup', child: Text('Top-up Kas')),
                    DropdownMenuItem(value: 'snack_tamu', child: Text('Snack / Tamu')),
                    DropdownMenuItem(value: 'transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'atk', child: Text('ATK')),
                    DropdownMenuItem(value: 'lain', child: Text('Lain-lain')),
                  ],
                  onChanged: (v) => setLocal(() => category = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (amountCtrl.text.isEmpty || descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Lengkapi nominal dan deskripsi'),
                        backgroundColor: AppColors.statusWarning),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final res = await _api.dio.post('/purchasing/petty-cash', data: {
        'amount': num.tryParse(amountCtrl.text) ?? 0,
        'direction': direction,
        'category': category,
        'description': descCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Transaksi tersimpan'),
          backgroundColor: res.data['success'] == true
              ? AppColors.statusSuccess
              : AppColors.statusDanger,
        ),
      );
      if (res.data['success'] == true) _load();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Gagal menyimpan transaksi';
      if (e is Exception) msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg), backgroundColor: AppColors.statusDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Kas Kecil Kantor',
        accentColor: AppColors.rolePurchasing,
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandPrimary,
        onPressed: _openForm,
        icon: const Icon(Icons.add_card, color: Colors.white),
        label: const Text('Catat Transaksi',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : Column(
                    children: [
                      _balanceCard(),
                      _filterBar(),
                      Expanded(
                        child: _transactions.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.receipt_long_outlined,
                                title: 'Belum Ada Transaksi',
                                subtitle: 'Catat kas masuk/keluar hari ini.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 100),
                                itemCount: _transactions.length,
                                itemBuilder: (c, i) => _txCard(
                                    _transactions[i] as Map<String, dynamic>),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _balanceCard() => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassWidget(
          padding: const EdgeInsets.all(18),
          tint: AppColors.rolePurchasing.withOpacity(0.1),
          borderColor: AppColors.rolePurchasing.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 32, color: AppColors.rolePurchasing),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Kas Kecil',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                        NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0)
                            .format(_balance),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rolePurchasing)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _filterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            _chip('Semua', 'all'),
            const SizedBox(width: 8),
            _chip('Masuk', 'in'),
            const SizedBox(width: 8),
            _chip('Keluar', 'out'),
          ],
        ),
      );

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
      selectedColor: AppColors.brandPrimary.withOpacity(0.15),
      labelStyle: TextStyle(
          color: selected ? AppColors.brandPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
    );
  }

  Widget _txCard(Map<String, dynamic> t) {
    final dir = (t['direction'] ?? '').toString();
    final amount = num.tryParse('${t['amount']}') ?? 0;
    final balanceAfter = num.tryParse('${t['balance_after']}') ?? 0;
    final performer = t['performer'] as Map<String, dynamic>?;
    final created = DateTime.tryParse(t['created_at'] ?? '');
    final isIn = dir == 'in';

    return GlassWidget(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderColor:
          (isIn ? AppColors.statusSuccess : AppColors.statusDanger).withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isIn
                      ? AppColors.statusSuccess
                      : AppColors.statusDanger)
                  .withOpacity(0.15),
            ),
            child: Icon(
              isIn ? Icons.add : Icons.remove,
              color:
                  isIn ? AppColors.statusSuccess : AppColors.statusDanger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['description'] ?? '-',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (t['category'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.brandSecondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t['category'],
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimary)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                          '${performer?['name'] ?? '-'} · ${created != null ? DateFormat('d MMM HH:mm', 'id_ID').format(created) : '-'}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount)}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isIn
                        ? AppColors.statusSuccess
                        : AppColors.statusDanger),
              ),
              Text(
                  'Saldo: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balanceAfter)}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
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
