import 'package:flutter/material.dart';
import 'package:smart_receipt/pages/history/transaction_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data untuk mensimulasikan daftar riwayat struk (LOGIKA TETAP)
    final List<Map<String, dynamic>> dummyTransactions = [
      {
        'title': 'Susu Kental Manis Kaleng',
        'date': '7 Juli 2026',
        'amount': 'Rp 85.000',
        'icon': Icons.inventory_2,
      },
      {
        'title': 'Sirup Frambozen & Fanta',
        'date': '6 Juli 2026',
        'amount': 'Rp 125.000',
        'icon': Icons.local_drink,
      },
      {
        'title': 'Es Batu Kristal (10 Karung)',
        'date': '5 Juli 2026',
        'amount': 'Rp 50.000',
        'icon': Icons.ac_unit,
      },
      {
        'title': 'Gelas Cup Plastik 16oz',
        'date': '3 Juli 2026',
        'amount': 'Rp 45.000',
        'icon': Icons.shopping_bag,
      },
      {
        'title': 'Kantong Plastik Takeaway',
        'date': '1 Juli 2026',
        'amount': 'Rp 15.000',
        'icon': Icons.shopping_basket,
      },
      {
        'title': 'Susu Kental Manis Kaleng',
        'date': '28 Juni 2026',
        'amount': 'Rp 85.000',
        'icon': Icons.inventory_2,
      },
      {
        'title': 'Sirup Frambozen',
        'date': '25 Juni 2026',
        'amount': 'Rp 60.000',
        'icon': Icons.local_drink,
      },
    ];

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
              icon: const Icon(Icons.filter_list, color: Color(0xFF00838F)),
              tooltip: 'Filter Data',
              onPressed: () {
                // Nanti untuk fitur filter bulan/minggu
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Kolom Pencarian (Search Bar) - Update Desain Floating
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
                decoration: InputDecoration(
                  hintText: 'Cari nama bahan baku atau toko...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF00ACC1),
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

          // 2. Daftar Riwayat menggunakan ListView.builder - Update Desain Kartu
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: dummyTransactions.length,
              itemBuilder: (context, index) {
                final trx = dummyTransactions[index];

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
                        color: const Color(0xFF00BCD4).withOpacity(0.15),
                        shape: BoxShape
                            .circle, // Latar ikon melingkar konsisten dengan Home
                      ),
                      child: Icon(
                        trx['icon'] as IconData,
                        color: const Color(0xFF00897B),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      trx['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        trx['date'] as String,
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
                          '- ${trx['amount']}',
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionDetailPage(transactionData: trx),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
