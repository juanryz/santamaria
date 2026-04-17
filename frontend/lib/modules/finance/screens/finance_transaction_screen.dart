import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_widget.dart';

const Map<String, String> _categoryLabels = {
  'jasa_funeral': 'Jasa Funeral',
  'paket_dasar': 'Paket Dasar',
  'paket_premium': 'Paket Premium',
  'paket_eksklusif': 'Paket Eksklusif',
  'add_on': 'Add-On',
  'pengadaan': 'Pengadaan',
  'upah_tukang_jaga': 'Upah Tukang Jaga',
  'vendor_dekor': 'Vendor Dekorasi',
  'vendor_konsumsi': 'Vendor Konsumsi',
  'vendor_pemuka_agama': 'Vendor Pemuka Agama',
  'vendor_foto': 'Vendor Foto',
  'vendor_angkat_peti': 'Vendor Angkat Peti',
  'operasional': 'Operasional',
  'manual_correction': 'Koreksi Manual',
};

class FinanceTransactionScreen extends StatefulWidget {
  const FinanceTransactionScreen({super.key});

  @override
  State<FinanceTransactionScreen> createState() =>
      _FinanceTransactionScreenState();
}

class _FinanceTransactionScreenState extends State<FinanceTransactionScreen> {
  final ApiClient _apiClient = ApiClient();

  // Filter state
  bool _filterExpanded = false;
  DateTime? _filterFrom;
  DateTime? _filterTo;
  String? _filterDirection; // null, 'in', 'out'
  final TextEditingController _searchCtrl = TextEditingController();

  // Data state
  bool _isLoading = false;
  String? _error;
  List<dynamic> _transactions = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  final ScrollController _scrollCtrl = ScrollController();
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  static const _roleColor = AppColors.roleFinance;

  @override
  void initState() {
    super.initState();
    _loadTransactions(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _transactions = [];
      });
    }

    try {
      final params = <String, dynamic>{'page': _page, 'per_page': 20};
      if (_filterFrom != null) {
        params['from'] = DateFormat('yyyy-MM-dd').format(_filterFrom!);
      }
      if (_filterTo != null) {
        params['to'] = DateFormat('yyyy-MM-dd').format(_filterTo!);
      }
      if (_filterDirection != null) params['direction'] = _filterDirection;
      if (_searchCtrl.text.trim().isNotEmpty) {
        params['search'] = _searchCtrl.text.trim();
      }

      final res = await _apiClient.dio.get(
        '/finance/transactions',
        queryParameters: params,
      );
      if (!mounted) return;

      final rawData = res.data['data'];
      List<dynamic> items = [];
      int? lastPage;
      if (rawData is Map) {
        items = (rawData['data'] as List<dynamic>?) ?? [];
        lastPage = rawData['last_page'] as int?;
      } else if (rawData is List) {
        items = rawData;
      }

      setState(() {
        if (reset) {
          _transactions = items;
        } else {
          _transactions.addAll(items);
        }
        _hasMore = lastPage != null ? _page < lastPage : items.length >= 20;
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat transaksi.';
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() {
      _isFetchingMore = true;
      _page++;
    });
    await _loadTransactions();
  }

  void _resetFilters() {
    setState(() {
      _filterFrom = null;
      _filterTo = null;
      _filterDirection = null;
      _searchCtrl.clear();
    });
    _loadTransactions(reset: true);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _filterFrom != null && _filterTo != null
          ? DateTimeRange(start: _filterFrom!, end: _filterTo!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.roleFinance),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _filterFrom = range.start;
        _filterTo = range.end;
      });
    }
  }

  Future<void> _voidTransaction(String id) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transaksi ini akan dibatalkan (void). Masukkan alasan:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan void (wajib)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _apiClient.dio.put(
        '/finance/transactions/$id/void',
        data: {'reason': reasonCtrl.text.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil di-void.')),
      );
      _loadTransactions(reset: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mem-void transaksi.')),
        );
      }
    }
  }

  void _showTransactionOptions(Map<String, dynamic> tx) {
    final isVoid = tx['is_void'] == true;
    if (isVoid) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opsi Transaksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.cancel_outlined,
                color: AppColors.statusDanger,
              ),
              title: const Text(
                'Batalkan (Void)',
                style: TextStyle(
                  color: AppColors.statusDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Tandai transaksi sebagai void',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _voidTransaction(tx['id'].toString());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openCorrectionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CorrectionFormSheet(
        apiClient: _apiClient,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadTransactions(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Transaksi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _filterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: _filterExpanded ? _roleColor : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _filterExpanded = !_filterExpanded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCorrectionForm,
        backgroundColor: _roleColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Koreksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (_filterExpanded) _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadTransactions(reset: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildError()
                  : _transactions.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount:
                          _transactions.length + (_isFetchingMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildTransactionCard(
                          _transactions[i] as Map<String, dynamic>,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.backgroundSoft,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.glassBorder),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: AppColors.textHint,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filterFrom != null && _filterTo != null
                          ? '${_dateFormat.format(_filterFrom!)} – ${_dateFormat.format(_filterTo!)}'
                          : 'Pilih rentang tanggal',
                      style: TextStyle(
                        color: _filterFrom != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_filterFrom != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterFrom = null;
                        _filterTo = null;
                      }),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textHint,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Direction dropdown
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.glassBorder),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filterDirection,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.expand_more,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Arah'),
                        ),
                        DropdownMenuItem(value: 'in', child: Text('Masuk')),
                        DropdownMenuItem(value: 'out', child: Text('Keluar')),
                      ],
                      onChanged: (v) => setState(() => _filterDirection = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Search
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.glassBorder),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari deskripsi...',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textHint,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.glassBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _loadTransactions(reset: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.statusDanger,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadTransactions(reset: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textHint,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada transaksi ditemukan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah filter pencarian',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final isIn = tx['direction'] == 'in';
    final isVoid = tx['is_void'] == true;
    final isCorrection = tx['is_correction'] == true;
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final category = tx['category'] as String? ?? '';
    final txType = tx['transaction_type'] as String? ?? '';
    final description = tx['description'] as String? ?? '';
    final dateStr =
        tx['transaction_date'] as String? ?? tx['created_at'] as String? ?? '';
    DateTime? txDate = DateTime.tryParse(dateStr);
    final barColor = isIn ? AppColors.statusSuccess : AppColors.statusDanger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: () => _showTransactionOptions(tx),
        child: Opacity(
          opacity: isVoid ? 0.5 : 1.0,
          child: GlassWidget(
            borderRadius: 14,
            blurSigma: 10,
            tint: AppColors.glassWhite,
            borderColor: AppColors.glassBorder,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left color bar
                    Container(width: 5, color: barColor),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (txDate != null)
                                        Text(
                                          _dateFormat.format(txDate),
                                          style: const TextStyle(
                                            color: AppColors.textHint,
                                            fontSize: 11,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      // Category + type chips row
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (category.isNotEmpty)
                                            _chip(
                                              _categoryLabels[category] ??
                                                  category,
                                              _roleColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              _roleColor,
                                            ),
                                          if (txType.isNotEmpty &&
                                              txType != category)
                                            _chip(
                                              txType,
                                              AppColors.backgroundSoft,
                                              AppColors.textSecondary,
                                            ),
                                          if (isCorrection)
                                            _chip(
                                              'KOREKSI',
                                              AppColors.statusWarning
                                                  .withValues(alpha: 0.15),
                                              AppColors.statusWarning,
                                            ),
                                          if (isVoid)
                                            _chip(
                                              'VOID',
                                              AppColors.statusDanger.withValues(
                                                alpha: 0.15,
                                              ),
                                              AppColors.statusDanger,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  _currency.format(amount),
                                  style: TextStyle(
                                    color: isIn
                                        ? AppColors.statusSuccess
                                        : AppColors.statusDanger,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: isVoid
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Correction Form Bottom Sheet ─────────────────────────────────────────────

class _CorrectionFormSheet extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onSuccess;

  const _CorrectionFormSheet({
    required this.apiClient,
    required this.onSuccess,
  });

  @override
  State<_CorrectionFormSheet> createState() => _CorrectionFormSheetState();
}

class _CorrectionFormSheetState extends State<_CorrectionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String _direction = 'in';
  final _amountCtrl = TextEditingController();
  String? _selectedCategory;
  final _descCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime _txDate = DateTime.now();
  bool _isSubmitting = false;

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  static const _roleColor = AppColors.roleFinance;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.apiClient.dio.post(
        '/finance/transactions/correction',
        data: {
          'direction': _direction,
          'amount':
              double.tryParse(
                _amountCtrl.text.replaceAll('.', '').replaceAll(',', ''),
              ) ??
              0,
          'category': _selectedCategory,
          'description': _descCtrl.text.trim(),
          'transaction_date': DateFormat('yyyy-MM-dd').format(_txDate),
          'correction_reason': _reasonCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koreksi berhasil ditambahkan.')),
        );
        widget.onSuccess();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan koreksi.')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tambah Koreksi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Direction toggle
              const Text(
                'Arah',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _direction = 'in'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _direction == 'in'
                              ? AppColors.statusSuccess
                              : AppColors.backgroundSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: _direction == 'in'
                                  ? Colors.white
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Masuk',
                              style: TextStyle(
                                color: _direction == 'in'
                                    ? Colors.white
                                    : AppColors.textHint,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _direction = 'out'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _direction == 'out'
                              ? AppColors.statusDanger
                              : AppColors.backgroundSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: _direction == 'out'
                                  ? Colors.white
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                color: _direction == 'out'
                                    ? Colors.white
                                    : AppColors.textHint,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Jumlah (Rp)', Icons.attach_money),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration(
                  'Kategori',
                  Icons.category_outlined,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                dropdownColor: Colors.white,
                items: _categoryLabels.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  'Deskripsi',
                  Icons.description_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Transaction date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _txDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.roleFinance,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _txDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.glassBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.textHint,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _dateFormat.format(_txDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Correction reason
              TextFormField(
                controller: _reasonCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Alasan Koreksi', Icons.edit_note),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Koreksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.roleFinance, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
