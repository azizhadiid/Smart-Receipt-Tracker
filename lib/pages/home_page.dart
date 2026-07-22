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
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- LOGIKA MENGAMBIL DATA DASHBOARD ---
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

  // --- HELPER UNTUK FORMAT TAMPILAN ---
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
      // RefreshIndicator memungkinkan user menarik layar ke bawah untuk reload data
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: Colors.teal,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Wajib agar RefreshIndicator bekerja walau konten sedikit
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sapaan Pengguna
                    Text(
                      'Halo, ${_getGreeting()}! 👋',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userName, // Nama dinamis dari database
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // 2. Kartu Ringkasan (Summary Card)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pengeluaran (Bulan Ini)',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_totalExpense),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Batas: ${_formatRupiah(_budgetLimit)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  // Ubah warna latar menjadi merah transparan jika overbudget
                                  color: isOverBudget ? Colors.red.withOpacity(0.8) : Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isOverBudget 
                                      ? 'Overbudget: ${_formatRupiah(remainingBudget.abs())}' 
                                      : 'Sisa: ${_formatRupiah(remainingBudget)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Header Bagian Transaksi Terakhir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Terakhir',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigasi ke Halaman History dan panggil reload saat kembali (opsional)
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryPage()),
                            ).then((_) => _fetchDashboardData()); 
                          },
                          child: const Text('Lihat Semua', style: TextStyle(color: Colors.teal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Daftar Transaksi Terakhir Dinamis
                    if (_recentTransactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada transaksi bulan ini.',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._recentTransactions.map((tx) {
                        return _buildTransactionItem(
                          context,
                          icon: Icons.receipt_outlined, // Bisa disesuaikan nanti dengan kategori
                          title: tx['title'].toString(),
                          date: _formatDate(tx['transaction_date'].toString()),
                          amount: '- ${_formatRupiah((tx['amount'] as num).toDouble())}',
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget custom list transaksi berulang
  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String date,
    required String amount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.redAccent, 
          ),
        ),
      ),
    );
  }
}