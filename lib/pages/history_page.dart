import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_receipt/pages/history/transaction_detail_page.dart';

enum _HistoryFilter { all, today, last7Days, thisMonth }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _HistoryFilter _activeFilter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    final keyword = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month);

    return _transactions.where((transaction) {
      final title = (transaction['title'] ?? '').toString().toLowerCase();
      final amount = formatRupiah(transaction['amount']).toLowerCase();
      final dateText = formatDate(transaction['transaction_date']).toLowerCase();
      final matchesSearch =
          keyword.isEmpty ||
          title.contains(keyword) ||
          amount.contains(keyword) ||
          dateText.contains(keyword);

      final dateValue = transaction['transaction_date'];
      final transactionDate = dateValue == null
          ? null
          : DateTime.tryParse(dateValue.toString())?.toLocal();
      final matchesFilter = switch (_activeFilter) {
        _HistoryFilter.all => true,
        _HistoryFilter.today =>
          transactionDate != null && !transactionDate.isBefore(startOfToday),
        _HistoryFilter.last7Days =>
          transactionDate != null &&
              !transactionDate.isBefore(startOfToday.subtract(const Duration(days: 6))),
        _HistoryFilter.thisMonth =>
          transactionDate != null && !transactionDate.isBefore(startOfMonth),
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String get _activeFilterLabel => switch (_activeFilter) {
    _HistoryFilter.all => 'Semua transaksi',
    _HistoryFilter.today => 'Hari ini',
    _HistoryFilter.last7Days => '7 hari terakhir',
    _HistoryFilter.thisMonth => 'Bulan ini',
  };

  Future<void> _showFilterSheet() async {
    final selectedFilter = await showModalBottomSheet<_HistoryFilter>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter riwayat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Pilih periode transaksi yang ingin ditampilkan.'),
              const SizedBox(height: 12),
              ..._HistoryFilter.values.map(
                (filter) => RadioListTile<_HistoryFilter>(
                  value: filter,
                  groupValue: _activeFilter,
                  activeColor: const Color(0xFF00897B),
                  contentPadding: EdgeInsets.zero,
                  title: Text(_filterLabel(filter)),
                  onChanged: (value) => Navigator.pop(sheetContext, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedFilter != null && mounted) {
      setState(() => _activeFilter = selectedFilter);
    }
  }

  String _filterLabel(_HistoryFilter filter) => switch (filter) {
    _HistoryFilter.all => 'Semua transaksi',
    _HistoryFilter.today => 'Hari ini',
    _HistoryFilter.last7Days => '7 hari terakhir',
    _HistoryFilter.thisMonth => 'Bulan ini',
  };

  // --- LOGIKA MENGAMBIL DATA DARI SUPABASE ---
  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Mengambil data dari tabel 'transactions' diurutkan berdasarkan tanggal terbaru
      final response = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data riwayat')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper untuk format mata uang Rupiah
  String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(double.parse(amount.toString()));
  }

  // Helper untuk format tanggal
  String formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;
    final hasActiveFilter = _activeFilter != _HistoryFilter.all;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background bersih
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F), // Cyan gelap modern
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                hasActiveFilter ? Icons.filter_alt : Icons.filter_list,
                color: const Color(0xFF00838F),
              ),
              tooltip: 'Filter Data',
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Kolom Pencarian (Search Bar)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari transaksi atau nominal...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF00ACC1),
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.filter_alt, size: 18),
                  label: Text(_activeFilterLabel),
                  onPressed: _showFilterSheet,
                  onDeleted: () => setState(() => _activeFilter = _HistoryFilter.all),
                ),
              ),
            ),

          // 2. Daftar Riwayat
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
                  )
                : filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _transactions.isEmpty
                              ? Icons.receipt_long
                              : Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _transactions.isEmpty
                              ? 'Belum ada transaksi.'
                              : 'Tidak ada transaksi yang sesuai.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF00BCD4),
                    onRefresh: _fetchTransactions,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final trx = filteredTransactions[index];
                        final formattedAmount = formatRupiah(trx['amount']);
                        final formattedDate = formatDate(
                          trx['transaction_date'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00BCD4,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt, // Ikon default struk
                                color: Color(0xFF00897B),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              trx['title'] ?? 'Tanpa Judul',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '- $formattedAmount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: () async {
                              // Menunggu navigasi kembali, jika dihapus (return true), maka refresh
                              final bool? shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionDetailPage(
                                    transactionData: trx,
                                  ),
                                ),
                              );

                              if (shouldRefresh == true) {
                                _fetchTransactions();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
