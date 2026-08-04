import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_receipt/pages/history_page.dart';
import 'package:smart_receipt/pages/home/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String _userName = 'Pengguna';
  double _budgetLimit = 0;
  double _totalExpense = 0;
  List<dynamic> _recentTransactions = [];

  final List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- LOGIKA MENGAMBIL DATA DASHBOARD (TIDAK DIUBAH) ---
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Ambil Nama dan Batas Budget dari tabel profiles
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('full_name, budget_limit')
          .eq('id', user.id)
          .single();

      _userName = profileData['full_name'] ?? 'Pengguna';
      _budgetLimit = (profileData['budget_limit'] as num?)?.toDouble() ?? 0;

      // 2. Tentukan rentang tanggal untuk "Bulan Ini"
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 3. Ambil Transaksi Bulan Ini
      final transactions = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .gte('transaction_date', startOfMonth.toIso8601String())
          .lte('transaction_date', endOfMonth.toIso8601String())
          .order('transaction_date', ascending: false);

      // 4. Hitung Total Pengeluaran Bulan Ini
      double expense = 0;
      for (var t in transactions) {
        expense += (t['amount'] as num).toDouble();
      }
      _totalExpense = expense;

      // 5. Ambil 3 Transaksi Terakhir untuk ditampilkan di daftar bawah
      _recentTransactions = transactions.take(3).toList();
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER UNTUK FORMAT TAMPILAN (TIDAK DIUBAH) ---
  String _formatRupiah(double value) {
    String strValue = value.toStringAsFixed(0);
    String formatted = '';
    int count = 0;
    for (int i = strValue.length - 1; i >= 0; i--) {
      count++;
      formatted = strValue[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    return 'Rp $formatted';
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung sisa budget
    final double remainingBudget = _budgetLimit - _totalExpense;
    final bool isOverBudget = remainingBudget < 0;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background yang bersih dan modern
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF00838F),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00838F)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Color(0xFF00838F),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // LayoutBuilder untuk mendukung responsivitas di berbagai layar
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final horizontalPadding = isNarrow ? 16.0 : 24.0;

          return RefreshIndicator(
            onRefresh: _fetchDashboardData,
            color: const Color(0xFF00BCD4),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
                  )
                : SingleChildScrollView(
                    // BouncingScrollPhysics menjamin scroll smooth & selalu bekerja saat di-pull/swipe
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    // Padding bawah 108 untuk mencegah konten terpotong BottomNavigationBar (karena extendBody: true)
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16.0,
                      horizontalPadding,
                      108.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. SAPAAN PENGGUNA ---
                        Text(
                          'Halo, ${_getGreeting()}! 👋',
                          style: TextStyle(
                            fontSize: isNarrow ? 14 : 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: isNarrow ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00838F),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- 2. KARTU RINGKASAN (SUMMARY CARD - RESPONSIVE) ---
                        Container(
                          padding: EdgeInsets.all(isNarrow ? 18 : 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00BCD4).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -10,
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  size: isNarrow ? 100 : 120,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Pengeluaran (Bulan Ini)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // FittedBox mencegah overflow saat angka jutaan / milyar
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatRupiah(_totalExpense),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isNarrow ? 28 : 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Wrap menggantikan Row agar tidak overflow di layar sempit
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Batas: ${_formatRupiah(_budgetLimit)}',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: isNarrow ? 12 : 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isNarrow ? 10 : 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOverBudget
                                              ? Colors.redAccent
                                              : Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isOverBudget
                                                ? Colors.red.shade300
                                                : Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isOverBudget
                                              ? 'Overbudget: ${_formatRupiah(remainingBudget.abs())}'
                                              : 'Sisa: ${_formatRupiah(remainingBudget)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isNarrow ? 11 : 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- 3. HEADER TRANSAKSI TERAKHIR ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaksi Terakhir',
                              style: TextStyle(
                                fontSize: isNarrow ? 16 : 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00838F),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HistoryPage(),
                                  ),
                                ).then((_) => _fetchDashboardData());
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                alignment: Alignment.centerRight,
                              ),
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: Color(0xFF00ACC1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // --- 4. DAFTAR TRANSAKSI TERAKHIR ---
                        if (_recentTransactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      size: 60,
                                      color: Color(0xFFB2EBF2),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada transaksi bulan ini.',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._recentTransactions.map((tx) {
                            return _buildTransactionItem(
                              context,
                              icon: Icons.receipt_outlined,
                              title: tx['title'].toString(),
                              date: _formatDate(
                                tx['transaction_date'].toString(),
                              ),
                              amount:
                                  '- ${_formatRupiah((tx['amount'] as num).toDouble())}',
                              isNarrow: isNarrow,
                            );
                          }),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  // --- WIDGET CUSTOM LIST TRANSAKSI (RESPONSIVE) ---
  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    bool isNarrow = false,
  }) {
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 14 : 20,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isNarrow ? 10 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00897B),
                size: isNarrow ? 20 : 24,
              ),
            ),
            SizedBox(width: isNarrow ? 10 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isNarrow ? 14 : 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isNarrow ? 11 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isNarrow ? 14 : 16,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
